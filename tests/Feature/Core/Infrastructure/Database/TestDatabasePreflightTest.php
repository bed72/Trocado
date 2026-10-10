<?php

declare(strict_types=1);

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\Support\Core\Database\TestDatabaseGuard;
use Tests\Support\Core\Database\TestDatabasePreflight;
use Tests\Support\Core\Database\TestDatabaseRun;

it('prepares an empty database and applies pending migrations without losing existing rows', function (): void {
    $original = config('database.connections.pgsql');
    $run = TestDatabaseRun::create();
    $preflight = new TestDatabasePreflight($run);
    DB::purge('pgsql');
    config(['database.connections.pgsql.database' => $run->database]);

    try {
        $preflight->provision($this->app);
        $preflight->provision($this->app);
        (new TestDatabaseGuard($run))->application($this->app);
        expect(Schema::hasTable('users'))->toBeFalse();

        $preflight->migrate($this->app, ['database/migrations/2026_09_21_000000_create_users_table.php']);
        $userId = DB::table('users')->insertGetId(['name' => 'Maria', 'email' => 'preflight@example.com']);
        expect(DB::table('migrations')->count())->toBe(1)
            ->and(Schema::hasTable('expenses'))->toBeFalse();

        $preflight->migrate($this->app);
        $migrations = DB::table('migrations')->orderBy('id')->get()->all();
        expect(Schema::hasTable('expenses'))->toBeTrue()
            ->and(Schema::hasTable('personal_access_tokens'))->toBeTrue()
            ->and(Schema::hasTable('jobs'))->toBeTrue()
            ->and(Schema::hasTable('failed_jobs'))->toBeTrue()
            ->and(DB::table('users')->where('id', $userId)->value('email'))->toBe('preflight@example.com');

        $preflight->migrate($this->app);
        expect(DB::table('migrations')->orderBy('id')->get()->all())->toEqual($migrations)
            ->and(DB::table('users')->where('id', $userId)->value('email'))->toBe('preflight@example.com');
    } finally {
        try {
            $preflight->cleanup($this->app);
        } finally {
            DB::purge('pgsql');
            config(['database.connections.pgsql' => $original]);
        }
    }

    expect(DB::connection('test_preflight_admin')->selectOne('select datname from pg_database where datname = ?', [$run->database]))->toBeNull();
    DB::purge('test_preflight_admin');
});

it('refuses to migrate or clean a different configured destination', function (): void {
    $original = config('database.connections.pgsql');
    $run = TestDatabaseRun::create();
    $preflight = new TestDatabasePreflight($run);
    DB::purge('pgsql');
    config(['database.connections.pgsql.database' => $run->database]);

    try {
        $preflight->provision($this->app);
        DB::purge('pgsql');
        config(['database.connections.pgsql.database' => 'trocado']);

        expect(fn () => $preflight->migrate($this->app))->toThrow(RuntimeException::class, 'Unsafe test database configuration')
            ->and(fn () => $preflight->cleanup($this->app))->toThrow(RuntimeException::class, 'Unsafe test database configuration');
    } finally {
        config(['database.connections.pgsql.database' => $run->database]);

        try {
            $preflight->cleanup($this->app);
        } finally {
            DB::purge('pgsql');
            config(['database.connections.pgsql' => $original]);
        }
    }
});

it('refuses reuse with another owner and does not drop a database reused by another preparer', function (): void {
    $original = config('database.connections.pgsql');
    $run = TestDatabaseRun::create();
    $creator = new TestDatabasePreflight($run);
    $reuser = new TestDatabasePreflight($run);
    DB::purge('pgsql');
    config(['database.connections.pgsql.database' => $run->database]);

    try {
        $creator->provision($this->app);
        $reuser->provision($this->app);
        $reuser->cleanup($this->app);
        (new TestDatabaseGuard($run))->application($this->app);

        $admin = DB::connection('test_preflight_admin');
        $admin->statement('COMMENT ON DATABASE "'.$run->database.'" IS \'another-execution\'');

        expect(fn () => (new TestDatabasePreflight($run))->provision($this->app))->toThrow(RuntimeException::class, 'not owned by this execution')
            ->and(fn () => $creator->cleanup($this->app))->toThrow(RuntimeException::class, 'Unsafe effective test connection');
    } finally {
        DB::connection('test_preflight_admin')->statement('COMMENT ON DATABASE "'.$run->database.'" IS '.DB::connection('test_preflight_admin')->getPdo()->quote($run->marker()));

        try {
            $creator->cleanup($this->app);
        } finally {
            DB::purge('pgsql');
            config(['database.connections.pgsql' => $original]);
        }
    }

    expect(DB::connection('test_preflight_admin')->selectOne('select datname from pg_database where datname = ?', [$run->database]))->toBeNull();
    DB::purge('test_preflight_admin');
});
