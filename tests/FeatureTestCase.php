<?php

declare(strict_types=1);

namespace Tests;

use Carbon\Carbon;
use Carbon\CarbonImmutable;
use Tests\Support\Core\Database\TestDatabaseCleanup;
use Tests\Support\Core\Database\TestDatabaseGuard;
use Tests\Support\Core\Database\TestDatabaseRun;
use Tests\Support\Core\Fixtures\TestResources;

abstract class FeatureTestCase extends TestCase
{
    public TestResources $resources;

    private string $originalTimezone;

    protected function setUp(): void
    {
        $this->originalTimezone = date_default_timezone_get();
        parent::setUp();

        (new TestDatabaseGuard(TestDatabaseRun::fromEnvironment()))->application($this->app);

        TestDatabaseCleanup::clean($this->app);
        $this->resources = new TestResources($this->app);
    }

    protected function tearDown(): void
    {
        try {
            if (isset($this->resources)) {
                $this->resources->close();
            }
        } finally {
            try {
                if ($this->app !== null) {
                    TestDatabaseCleanup::clean($this->app);
                    $this->app['auth']->forgetGuards();
                    foreach ($this->app['db']->getConnections() as $connection) {
                        $connection->disconnect();
                    }
                }
            } finally {
                Carbon::setTestNow();
                CarbonImmutable::setTestNow();
                try {
                    parent::tearDown();
                } finally {
                    date_default_timezone_set($this->originalTimezone);
                }
            }
        }
    }
}
