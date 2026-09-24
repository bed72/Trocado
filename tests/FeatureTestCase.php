<?php

declare(strict_types=1);

namespace Tests;

use Illuminate\Support\Facades\DB;
use RuntimeException;

abstract class FeatureTestCase extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        $maintenance = DB::connection('pgsql_maintenance');

        if ($maintenance->selectOne('select current_database() as name')->name !== 'trocado_testing'
            || $maintenance->selectOne('select current_user as name')->name === DB::selectOne('select current_user as name')->name) {
            throw new RuntimeException('Feature tests require a separate maintenance role on trocado_testing.');
        }

        $maintenance->statement('TRUNCATE TABLE users, personal_access_tokens, expenses RESTART IDENTITY CASCADE');
    }

    protected function tearDown(): void
    {
        DB::disconnect('pgsql_maintenance');
        DB::disconnect();

        parent::tearDown();
    }
}
