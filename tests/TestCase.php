<?php

declare(strict_types=1);

namespace Tests;

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Tests\Support\Core\Database\TestDatabaseGuard;
use Tests\Support\Core\Database\TestDatabaseRun;

abstract class TestCase extends BaseTestCase
{
    public function createApplication(): Application
    {
        $run = TestDatabaseRun::fromEnvironment();
        $app = parent::createApplication();
        (new TestDatabaseGuard(TestDatabaseRun::fromEnvironment(false)))->configuration($app['config']->get('database.default'), $app['config']->get('database.connections.pgsql'));
        $app['db']->purge('pgsql');
        $app['config']->set('database.connections.pgsql.database', $run->database);
        (new TestDatabaseGuard($run))->application($app);

        return $app;
    }
}
