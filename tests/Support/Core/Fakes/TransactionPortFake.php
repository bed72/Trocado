<?php

declare(strict_types=1);

namespace Tests\Support\Core\Fakes;

use App\Core\Application\Ports\TransactionPort;
use LogicException;
use Throwable;

/** Observes orchestration only; does not roll back repositories or simulate savepoints/retries. */
final class TransactionPortFake implements TransactionPort
{
    public bool $isActive = false;

    public int $commitCount = 0;

    public int $callbackCount = 0;

    public int $discardedCallbackCount = 0;

    /** @var list<mixed> */
    public array $committedResults = [];

    /** @var list<Throwable> */
    public array $abortedFailures = [];

    /** @var list<string> */
    public array $trace = [];

    /** @var list<callable(): void> */
    private array $attemptCallbacks = [];

    /** @var list<callable(): void> */
    private array $confirmedCallbacks = [];

    public function commit(callable $operation): mixed
    {
        if ($this->isActive) {
            throw new LogicException('Nested transactions need a real database proof, not TransactionPortFake.');
        }

        $this->commitCount++;
        $this->isActive = true;
        $this->trace[] = 'begin';

        try {
            $result = $operation();
        } catch (Throwable $exception) {
            $this->discardedCallbackCount += count($this->attemptCallbacks);
            $this->attemptCallbacks = [];
            $this->abortedFailures[] = $exception;
            $this->trace[] = 'abort';

            throw $exception;
        } finally {
            $this->isActive = false;
        }

        $this->committedResults[] = $result;
        $this->confirmedCallbacks = [...$this->confirmedCallbacks, ...$this->attemptCallbacks];
        $this->attemptCallbacks = [];
        $this->trace[] = 'commit';

        return $result;
    }

    public function afterCommit(callable $callback): void
    {
        $this->callbackCount++;
        $this->trace[] = 'register';

        if ($this->isActive) {
            $this->attemptCallbacks[] = $callback;

            return;
        }

        $this->trace[] = 'callback';
        $callback();
    }

    public function releaseAfterCommit(): void
    {
        if ($this->isActive) {
            throw new LogicException('Cannot release callbacks before the simulated commit.');
        }

        $callbacks = $this->confirmedCallbacks;
        $this->confirmedCallbacks = [];

        foreach ($callbacks as $callback) {
            $this->trace[] = 'callback';
            $callback();
        }
    }
}
