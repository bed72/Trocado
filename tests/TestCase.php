<?php

declare(strict_types=1);

namespace Tests;

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use RuntimeException;

abstract class TestCase extends BaseTestCase
{
    public function createApplication(): Application
    {
        $app = parent::createApplication();
        $database = $app->make('db');

        if ($database->getDefaultConnection() !== 'pgsql'
            || $app['config']->get('database.connections.pgsql.driver') !== 'pgsql'
            || filled($app['config']->get('database.connections.pgsql.url'))
            || $app['config']->get('database.connections.pgsql.database') !== 'trocado_testing') {
            throw new RuntimeException('Tests require the dedicated PostgreSQL trocado_testing database without DB_URL.');
        }

        if ($database->connection()->selectOne('select current_database() as name')->name !== 'trocado_testing') {
            throw new RuntimeException('The effective test connection must point to trocado_testing.');
        }

        $role = $database->connection()->selectOne('select current_user as name, rolsuper, rolbypassrls from pg_roles where rolname = current_user');

        if ($role->name !== 'trocado_runtime' || $role->rolsuper || $role->rolbypassrls) {
            throw new RuntimeException('Tests require the limited trocado_runtime role.');
        }

        return $app;
    }
}
