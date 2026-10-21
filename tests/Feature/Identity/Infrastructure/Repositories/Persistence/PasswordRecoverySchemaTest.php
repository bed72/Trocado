<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Auth\Passwords\DatabaseTokenRepository;
use Illuminate\Auth\Passwords\PasswordBrokerManager;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('provides only the native recovery columns and a unique canonical email key on PostgreSQL', function (): void {
    expect(DB::connection()->getDriverName())->toBe('pgsql')
        ->and(Schema::getColumnListing('password_reset_tokens'))->toBe(['email', 'token', 'created_at']);
    $indexes = Schema::getIndexes('password_reset_tokens');
    $primary = array_values(array_filter($indexes, fn (array $index): bool => $index['primary']));
    expect($primary)->toHaveCount(1)
        ->and($primary[0]['columns'])->toBe(['email'])
        ->and($primary[0]['unique'])->toBeTrue();

    DB::table('password_reset_tokens')->insert([
        'email' => 'maria@example.com', 'token' => Hash::make('first-test-token'), 'created_at' => '2026-10-21 12:00:00',
    ]);
    expect(fn () => DB::table('password_reset_tokens')->insert([
        'email' => 'maria@example.com', 'token' => Hash::make('second-test-token'), 'created_at' => '2026-10-21 12:01:00',
    ]))->toThrow(UniqueConstraintViolationException::class);
    expect(DB::table('password_reset_tokens')->count())->toBe(1);
});

it('supports the native hash only storage on the transaction connection with the approved configuration', function (): void {
    $this->travelTo(now()->setDate(2026, 10, 21)->setTime(12, 0));
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $repository = app(PasswordBrokerManager::class)->broker('users')->getRepository();
    expect($repository)->toBeInstanceOf(DatabaseTokenRepository::class)
        ->and($repository->getConnection())->toBe(DB::connection())
        ->and(config('auth.passwords.users.expire'))->toBe(30)
        ->and(config('auth.passwords.users.throttle'))->toBe(60);

    $token = DB::transaction(fn (): string => $repository->create($user));
    $record = (array) DB::table('password_reset_tokens')->sole();
    expect(array_keys($record))->toBe(['email', 'token', 'created_at'])
        ->and($record['email'])->toBe('maria@example.com')
        ->and($record['token'])->not->toBe($token)
        ->and(Hash::check($token, $record['token']))->toBeTrue()
        ->and($record['created_at'])->toBe('2026-10-21 12:00:00');
});

it('can reverse and reapply only the new migration inside its owned test database', function (): void {
    $migration = require database_path('migrations/2026_10_21_170047_create_password_reset_tokens_table.php');

    DB::transaction(function () use ($migration): void {
        $migration->down();
        expect(Schema::hasTable('password_reset_tokens'))->toBeFalse()
            ->and(Schema::hasTable('users'))->toBeTrue();
        $migration->up();
        expect(Schema::getColumnListing('password_reset_tokens'))->toBe(['email', 'token', 'created_at']);
    });
});
