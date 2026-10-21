<?php

declare(strict_types=1);

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\Support\Core\Database\TestDatabaseCleanup;

it('cleans classified recovery rows and abandons uncommitted state without changing migrations', function (): void {
    $migrations = DB::table('migrations')->orderBy('id')->get()->all();
    DB::table('password_reset_tokens')->insert([
        'email' => 'committed@example.com', 'token' => Hash::make('test-committed'), 'created_at' => '2026-10-21 12:00:00',
    ]);
    DB::beginTransaction();
    DB::table('password_reset_tokens')->insert([
        'email' => 'uncommitted@example.com', 'token' => Hash::make('test-uncommitted'), 'created_at' => '2026-10-21 12:00:00',
    ]);
    expect(DB::table('password_reset_tokens')->count())->toBe(2);

    TestDatabaseCleanup::clean($this->app);

    expect(DB::transactionLevel())->toBe(0)
        ->and(DB::table('password_reset_tokens')->count())->toBe(0)
        ->and(DB::table('migrations')->orderBy('id')->get()->all())->toEqual($migrations);
});
