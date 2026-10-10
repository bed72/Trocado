<?php

declare(strict_types=1);

namespace Tests\Support\Core\Database;

use Closure;
use Illuminate\Foundation\Application;
use RuntimeException;

final readonly class TestDatabaseGuard
{
    public function __construct(private TestDatabaseRun $run) {}

    /** @param array<string, mixed> $connection */
    public function configuration(string $default, array $connection): void
    {
        if ($default !== 'pgsql' || ($connection['driver'] ?? null) !== 'pgsql'
            || ! in_array($connection['url'] ?? null, [null, ''], true)
            || ($connection['database'] ?? null) !== $this->run->database
            || isset($connection['read']) || isset($connection['write'])
            || ($connection['search_path'] ?? 'public') !== 'public') {
            throw new RuntimeException('Unsafe test database configuration: require the exact registered PostgreSQL database, without DB_URL or read/write overrides.');
        }
    }

    /**
     * @param  array<string, mixed>  $connection
     * @param  Closure(): array{name: string, owner: ?string}  $identify
     */
    public function verify(string $default, array $connection, Closure $identify): void
    {
        $this->configuration($default, $connection);
        $identity = $identify();

        if ($identity['name'] !== $this->run->database || $identity['owner'] !== $this->run->marker()) {
            throw new RuntimeException('Unsafe effective test connection: database or execution ownership differs.');
        }
    }

    public function application(Application $app): void
    {
        $database = $app->make('db');
        $default = $database->getDefaultConnection();
        $config = $app['config']->get('database.connections.'.$default, []);

        $this->verify($default, $config, static function () use ($database): array {
            $connection = $database->connection();

            if ($connection->getDriverName() !== 'pgsql') {
                throw new RuntimeException('The effective driver must be PostgreSQL.');
            }

            $identity = $connection->selectOne("select current_database() as name, shobj_description(oid, 'pg_database') as owner from pg_database where datname = current_database()", [], false);

            return ['name' => $identity->name, 'owner' => $identity->owner];
        });
    }
}
