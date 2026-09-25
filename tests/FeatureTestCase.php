<?php

declare(strict_types=1);

namespace Tests;

use Illuminate\Support\Facades\DB;

abstract class FeatureTestCase extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        DB::table('personal_access_tokens')->delete();
        DB::table('expenses')->delete();
        DB::table('users')->delete();
    }

    protected function tearDown(): void
    {
        DB::disconnect();

        parent::tearDown();
    }
}
