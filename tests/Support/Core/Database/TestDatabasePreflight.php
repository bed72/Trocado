<?php

declare(strict_types=1);

namespace Tests\Support\Core\Database;

use Illuminate\Contracts\Console\Kernel;
use Illuminate\Database\Connection;
use Illuminate\Foundation\Application;
use RuntimeException;

final class TestDatabasePreflight
{
    private bool $created = false;

    private readonly TestDatabaseGuard $guard;

    public function __construct(private readonly TestDatabaseRun $run)
    {
        $this->guard = new TestDatabaseGuard($run);
    }

    public function provision(Application $app): void
    {
        $config = $app['config']->get('database.connections.pgsql');
        $this->guard->configuration($app['config']->get('database.default'), $config);
        $admin = $this->administration($app, $config);
        $existing = $admin->selectOne("select shobj_description(oid, 'pg_database') as owner from pg_database where datname = ?", [$this->run->database]);

        if ($existing !== null) {
            if ($existing->owner !== $this->run->marker()) {
                throw new RuntimeException('Refusing to reuse a database not owned by this execution.');
            }

            return;
        }

        $admin->statement('CREATE DATABASE "'.$this->run->database.'"');
        $this->created = true;
        $admin->statement('COMMENT ON DATABASE "'.$this->run->database.'" IS '.$admin->getPdo()->quote($this->run->marker()));
    }

    /** @param list<string> $paths */
    public function migrate(Application $app, array $paths = []): void
    {
        $this->guard->application($app);
        $arguments = ['--database' => 'pgsql', '--force' => true, '--no-interaction' => true];

        if ($paths !== []) {
            $arguments['--path'] = $paths;
        }

        $kernel = $app->make(Kernel::class);

        if ($kernel->call('migrate', $arguments) !== 0) {
            throw new RuntimeException('Incremental test migrations failed: '.$kernel->output());
        }

        $this->guard->application($app);
    }

    public function cleanup(Application $app): void
    {
        if (! $this->created) {
            return;
        }

        $this->guard->application($app);
        $database = $app->make('db');
        $config = $app['config']->get('database.connections.pgsql');
        $database->purge('pgsql');
        $admin = $this->administration($app, $config);
        $identity = $admin->selectOne("select shobj_description(oid, 'pg_database') as owner from pg_database where datname = ?", [$this->run->database]);

        if ($identity?->owner !== $this->run->marker()) {
            throw new RuntimeException('Refusing to drop a database with different ownership.');
        }

        $admin->statement('DROP DATABASE "'.$this->run->database.'"');
        $this->created = false;
        $database->purge('test_preflight_admin');
    }

    public function cleanupOwned(Application $app): void
    {
        $app['db']->purge('pgsql');
        $app['config']->set('database.connections.pgsql.database', $this->run->database);
        $this->cleanup($app);
    }

    /** @param array<string, mixed> $config */
    private function administration(Application $app, array $config): Connection
    {
        $config['database'] = 'postgres';
        $app['config']->set('database.connections.test_preflight_admin', $config);

        return $app->make('db')->connection('test_preflight_admin');
    }
}
