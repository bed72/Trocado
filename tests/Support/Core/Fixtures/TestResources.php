<?php

declare(strict_types=1);

namespace Tests\Support\Core\Fixtures;

use Illuminate\Foundation\Application;
use Redis;
use RuntimeException;
use Tests\Support\Core\Database\TestDatabaseRun;

final class TestResources
{
    public readonly string $namespace;

    public readonly string $log;

    public function __construct(private readonly Application $app)
    {
        $run = TestDatabaseRun::fromEnvironment();
        $this->namespace = 'trocado-test:'.$run->id.':'.($run->token ?? 'serial').':'.bin2hex(random_bytes(8)).':';
        $path = tempnam(sys_get_temp_dir(), str_replace(':', '-', $this->namespace));
        if ($path === false) {
            throw new RuntimeException('Cannot allocate isolated test log.');
        }
        $this->log = $path;
        $config = $app['config'];
        $config->set('database.redis.options.prefix', $this->namespace);
        $config->set('database.redis.options.persistent', false);
        $config->set('cache.prefix', $this->namespace);
        $config->set('queue.connections.redis.queue', $this->namespace.'queue');
        $config->set('queue.connections.database.queue', $this->namespace.'queue');
        $config->set('expense.classification.queue', $this->namespace.'classification');
        $config->set('logging.channels.single.path', $path);
        $config->set('logging.channels.daily.path', $path);
        $config->set('logging.channels.daily.driver', 'single');
        $config->set('logging.channels.observability_stderr.handler_with.stream', $path);
    }

    public function close(): void
    {
        try {
            if ($this->app->resolved('redis')) {
                $names = array_unique([...array_keys($this->app['redis']->connections()), 'default', 'cache']);
                foreach ($names as $name) {
                    $connection = $this->app['redis']->connection($name);
                    $client = $connection->client();
                    if (! $client instanceof Redis || $client->getOption(Redis::OPT_PREFIX) !== $this->namespace) {
                        throw new RuntimeException('Refusing cleanup of Redis outside the registered scenario namespace.');
                    }
                    $cursor = null;
                    $keys = [];
                    do {
                        $batch = $client->scan($cursor, $this->namespace.'*', 100);
                        if ($batch !== false) {
                            array_push($keys, ...$batch);
                        }
                    } while ($cursor !== 0);
                    foreach (array_unique($keys) as $key) {
                        $client->rawCommand('DEL', $key);
                    }
                    $connection->disconnect();
                    $this->app['redis']->purge($name);
                }
            }
        } finally {
            foreach (['single', 'daily', 'observability', 'observability_stderr'] as $channel) {
                $this->app['log']->forgetChannel($channel);
            }
            if (is_file($this->log)) {
                unlink($this->log);
            }
        }
    }
}
