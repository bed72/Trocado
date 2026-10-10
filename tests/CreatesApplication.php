<?php

declare(strict_types=1);

namespace Tests;

use Illuminate\Contracts\Console\Kernel;
use Illuminate\Foundation\Application;
use Tests\Support\Core\Database\TestDatabaseGuard;
use Tests\Support\Core\Database\TestDatabaseRun;

trait CreatesApplication
{
    /** Laravel's parallel runner resolves this trait before its database lifecycle hooks. */
    public function createApplication(): Application
    {
        $run = TestDatabaseRun::fromEnvironment(false);
        $app = require dirname(__DIR__).'/bootstrap/app.php';
        $app->make(Kernel::class)->bootstrap();
        (new TestDatabaseGuard($run))->application($app);

        return $app;
    }
}
