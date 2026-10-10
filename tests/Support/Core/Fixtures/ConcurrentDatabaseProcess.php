<?php

declare(strict_types=1);

namespace Tests\Support\Core\Fixtures;

use Closure;
use Illuminate\Support\Facades\DB;
use RuntimeException;
use Tests\Support\Core\Database\TestDatabaseGuard;
use Tests\Support\Core\Database\TestDatabaseRun;
use Throwable;

final class ConcurrentDatabaseProcess
{
    public readonly int $pid;

    private bool $closed = false;

    /** @var resource */
    private $socket;

    public readonly int $backendPid;

    public function __construct(Closure $operation)
    {
        if (! function_exists('pcntl_fork') || ! function_exists('posix_kill')) {
            throw new RuntimeException('Concurrency requires pcntl and posix; this integration cannot be skipped in the gate.');
        }
        foreach (DB::getConnections() as $connection) {
            if ($connection->transactionLevel() !== 0) {
                throw new RuntimeException('Fork must precede the parent transaction.');
            }
            $connection->disconnect();
        }
        if (app()->resolved('redis')) {
            foreach (app('redis')->connections() as $name => $connection) {
                $connection->disconnect();
                app('redis')->purge($name);
            }
        }
        $sockets = stream_socket_pair(STREAM_PF_UNIX, STREAM_SOCK_STREAM, STREAM_IPPROTO_IP);
        if ($sockets === false) {
            throw new RuntimeException('Cannot create concurrency socket.');
        }
        $pid = pcntl_fork();
        if ($pid === -1) {
            fclose($sockets[0]);
            fclose($sockets[1]);
            throw new RuntimeException('Cannot fork concurrency process.');
        }
        if ($pid === 0) {
            fclose($sockets[0]);
            stream_set_timeout($sockets[1], 5);
            $code = 0;
            try {
                (new TestDatabaseGuard(TestDatabaseRun::fromEnvironment()))->application(app());
                fwrite($sockets[1], 'ready:'.DB::selectOne('select pg_backend_pid() as pid')->pid."\n");
                if (trim((string) fgets($sockets[1])) !== 'go') {
                    throw new RuntimeException('Child did not receive go before timeout.');
                }
                $operation();
                fwrite($sockets[1], "done\n");
            } catch (Throwable $exception) {
                fwrite($sockets[1], 'error:'.$exception::class.':'.$exception->getMessage()."\n");
                $code = 1;
            } finally {
                foreach (DB::getConnections() as $connection) {
                    while ($connection->transactionLevel() > 0) {
                        $connection->rollBack();
                    }
                    $connection->disconnect();
                }
                fclose($sockets[1]);
            }
            exit($code);
        }
        fclose($sockets[1]);
        $this->pid = $pid;
        $this->socket = $sockets[0];
        stream_set_timeout($this->socket, 5);
        try {
            $ready = $this->receive();
            if (preg_match('/\Aready:([0-9]+)\z/', $ready, $match) !== 1) {
                throw new RuntimeException('Unexpected child readiness: '.$ready);
            }
            $this->backendPid = (int) $match[1];
        } catch (Throwable $exception) {
            $this->close();
            throw $exception;
        }
    }

    public function go(): void
    {
        if (fwrite($this->socket, "go\n") === false) {
            throw new RuntimeException('Cannot signal child.');
        }
    }

    public function awaitLock(): void
    {
        $deadline = microtime(true) + 3;
        do {
            if (DB::selectOne('select wait_event_type from pg_stat_activity where pid = ?', [$this->backendPid])?->wait_event_type === 'Lock') {
                return;
            }
            usleep(10000);
        } while (microtime(true) < $deadline);
        throw new RuntimeException('Child did not reach an observed PostgreSQL lock before timeout.');
    }

    public function done(): void
    {
        $message = $this->receive();
        if ($message !== 'done') {
            throw new RuntimeException('Unexpected child completion: '.$message);
        }
    }

    private function receive(): string
    {
        $message = fgets($this->socket);
        if ($message === false) {
            throw new RuntimeException('Child socket closed or timed out.');
        }
        if (str_starts_with($message, 'error:')) {
            throw new RuntimeException(trim($message));
        }

        return trim($message);
    }

    public function close(): void
    {
        if ($this->closed) {
            return;
        }
        $this->closed = true;
        if (is_resource($this->socket)) {
            fclose($this->socket);
        }
        $deadline = microtime(true) + 1;
        do {
            $result = pcntl_waitpid($this->pid, $status, WNOHANG);
            if ($result !== 0) {
                return;
            }
            usleep(10000);
        } while (microtime(true) < $deadline);
        posix_kill($this->pid, SIGKILL);
        pcntl_waitpid($this->pid, $status);
    }
}
