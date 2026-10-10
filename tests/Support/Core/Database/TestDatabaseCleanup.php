<?php

declare(strict_types=1);

namespace Tests\Support\Core\Database;

use Illuminate\Foundation\Application;
use RuntimeException;

final class TestDatabaseCleanup
{
    /** Child tables precede parents. New mutable tables must be classified here. */
    public const TABLES = ['failed_jobs', 'jobs', 'personal_access_tokens', 'expenses', 'users'];

    public static function clean(Application $app): void
    {
        $guard = new TestDatabaseGuard(TestDatabaseRun::fromEnvironment());
        $guard->configuration($app['config']->get('database.default'), $app['config']->get('database.connections.pgsql'));
        $connection = $app['db']->connection();
        while ($connection->transactionLevel() > 0) {
            $connection->rollBack();
        }
        $guard->application($app);
        $connection->disableQueryLog();
        $connection->flushQueryLog();
        $tables = array_column($connection->select("select tablename from pg_tables where schemaname = 'public'"), 'tablename');
        if (array_diff($tables, [...self::TABLES, 'migrations']) !== []) {
            throw new RuntimeException('Classify new test tables in TestDatabaseCleanup before using fixtures.');
        }
        foreach (self::TABLES as $table) {
            if (in_array($table, $tables, true)) {
                $connection->table($table)->delete();
            }
        }
    }
}
