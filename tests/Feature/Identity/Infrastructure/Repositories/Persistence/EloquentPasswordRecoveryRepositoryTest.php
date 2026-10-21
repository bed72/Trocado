<?php

declare(strict_types=1);

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Ports\PasswordRecoveryPort;
use App\Identity\Application\Repositories\PasswordRecoveryRepository;
use App\Identity\Application\UseCases\RequestPasswordRecoveryUseCase;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Infrastructure\Adapters\PasswordRecoveryAdapter;
use App\Identity\Infrastructure\Repositories\Persistence\EloquentPasswordRecoveryRepository;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Passwords\PasswordBrokerManager;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Tests\Support\Identity\Fixtures\IdentityFixture;
use Tests\Support\Identity\Spies\PasswordRecoveryPortSpy;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:00 UTC'));
    Notification::fake();
    $this->recoveryPort = new PasswordRecoveryPortSpy;
    $this->useCase = new RequestPasswordRecoveryUseCase(
        app(TransactionPort::class), $this->recoveryPort, app(PasswordRecoveryRepository::class),
    );
});

it('issues only a native token hash under account then recovery locks without changing the account or sessions', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    IdentityFixture::token($user, expiresAt: now()->addDay());
    $beforeUser = DB::table('users')->get()->all();
    $beforeSessions = DB::table('personal_access_tokens')->get()->all();
    expect(app(PasswordRecoveryRepository::class))->toBeInstanceOf(EloquentPasswordRecoveryRepository::class)
        ->and(app(PasswordRecoveryPort::class))->toBeInstanceOf(PasswordRecoveryAdapter::class);

    DB::enableQueryLog();
    DB::flushQueryLog();
    try {
        $result = $this->useCase->execute(' MARIA@EXAMPLE.COM ');
        $queries = array_column(DB::getQueryLog(), 'query');
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }

    expect($result)->toBeNull()
        ->and($queries[0])->toContain('"users"', 'for update')
        ->and($queries[1])->toContain('"password_reset_tokens"', 'for update')
        ->and($this->recoveryPort->links)->toHaveCount(1)
        ->and(DB::transactionLevel())->toBe(0);
    $link = $this->recoveryPort->links[0];
    $record = (array) DB::table('password_reset_tokens')->sole();
    expect($link['user_id'])->toBe($user->getKey())
        ->and($link['email'])->toBe('maria@example.com')
        ->and(array_keys($record))->toBe(['email', 'token', 'created_at'])
        ->and($record['token'])->not->toBe($link['token'])
        ->and(Hash::check($link['token'], $record['token']))->toBeTrue()
        ->and($record['created_at'])->toBe('2026-10-21 12:00:00')
        ->and(DB::table('users')->get()->all())->toEqual($beforeUser)
        ->and(DB::table('personal_access_tokens')->get()->all())->toEqual($beforeSessions);
    Notification::assertNothingSent();
});

it('does not emit for an ineligible missing removed or mismatched identity', function (?UserStatusEnum $status, bool $verified, bool $removed, string $email): void {
    if ($status !== null) {
        $user = IdentityFixture::create(status: $status, verifiedAt: $verified ? now() : null);
        if ($removed) {
            $user->delete();
        }
    }
    $before = DB::table('users')->get()->all();

    $this->useCase->execute($email);

    expect(DB::table('password_reset_tokens')->count())->toBe(0)
        ->and(DB::table('users')->get()->all())->toEqual($before)
        ->and($this->recoveryPort->links)->toBe([])
        ->and(DB::table('personal_access_tokens')->count())->toBe(0);
    Notification::assertNothingSent();
})->with([
    'active unverified' => [UserStatusEnum::Active, false, false, 'maria@example.com'],
    'pending verified' => [UserStatusEnum::Pending, true, false, 'maria@example.com'],
    'pending unverified' => [UserStatusEnum::Pending, false, false, 'maria@example.com'],
    'blocked verified' => [UserStatusEnum::Blocked, true, false, 'maria@example.com'],
    'blocked unverified' => [UserStatusEnum::Blocked, false, false, 'maria@example.com'],
    'missing' => [null, false, false, 'maria@example.com'],
    'removed' => [UserStatusEnum::Active, true, true, 'maria@example.com'],
    'different address' => [UserStatusEnum::Active, true, false, 'old@example.com'],
]);

it('suppresses canonical equivalents without changing the hash or deadline and rotates at exactly sixty seconds', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->useCase->execute('maria@example.com');
    $first = (array) DB::table('password_reset_tokens')->sole();
    $firstToken = $this->recoveryPort->links[0]['token'];

    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:59 UTC'));
    $otherPort = new PasswordRecoveryPortSpy;
    $otherUseCase = new RequestPasswordRecoveryUseCase(app(TransactionPort::class), $otherPort, app(PasswordRecoveryRepository::class));
    $otherUseCase->execute(' MARIA@EXAMPLE.COM ');
    expect((array) DB::table('password_reset_tokens')->sole())->toBe($first)
        ->and($otherPort->links)->toBe([]);
    $suppressed = app(TransactionPort::class)->commit(
        fn () => app(PasswordRecoveryRepository::class)->issue(EmailValueObject::fromString('maria@example.com')),
    );
    expect($suppressed->userId)->toBe($user->getKey())->and($suppressed->token)->toBeNull();

    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:01:00 UTC'));
    $otherUseCase->execute(' MARIA@EXAMPLE.COM ');
    $second = (array) DB::table('password_reset_tokens')->sole();
    $secondToken = $otherPort->links[0]['token'];
    $native = app(PasswordBrokerManager::class)->broker('users')->getRepository();
    expect(DB::table('password_reset_tokens')->count())->toBe(1)
        ->and($second['created_at'])->toBe('2026-10-21 12:01:00')
        ->and($second['token'])->not->toBe($first['token'])
        ->and($native->exists($user, $firstToken))->toBeFalse()
        ->and($native->exists($user, $secondToken))->toBeTrue()
        ->and($otherPort->links)->toHaveCount(1);
    $otherUseCase->execute('maria@example.com');
    expect((array) DB::table('password_reset_tokens')->sole())->toBe($second)
        ->and($otherPort->links)->toHaveCount(1);
});

it('rechecks eligibility without rotating an already issued recovery', function (array $changes): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->useCase->execute('maria@example.com');
    $before = (array) DB::table('password_reset_tokens')->sole();
    $user->forceFill($changes)->save();
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:01:00 UTC'));

    $this->useCase->execute('maria@example.com');

    expect((array) DB::table('password_reset_tokens')->sole())->toBe($before)
        ->and($this->recoveryPort->links)->toHaveCount(1);
})->with([
    'blocked' => [['status' => UserStatusEnum::Blocked]],
    'pending' => [['status' => UserStatusEnum::Pending]],
    'unverified' => [['email_verified_at' => null]],
    'address changed' => [['email' => 'new@example.com']],
]);

it('discards the after commit effect and restores the prior token on a real rollback', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    app(PasswordBrokerManager::class)->broker('users')->getRepository()->create($user);
    $before = (array) DB::table('password_reset_tokens')->sole();
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:01:00 UTC'));
    $failure = new RuntimeException('emission-rollback-sentinel');

    try {
        app(TransactionPort::class)->commit(function () use ($before, $failure): never {
            $this->useCase->execute('maria@example.com');
            expect(DB::table('password_reset_tokens')->value('token'))->not->toBe($before['token'])
                ->and($this->recoveryPort->links)->toBe([]);
            throw $failure;
        });
        $this->fail('The sentinel must propagate.');
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($failure);
    }

    expect((array) DB::table('password_reset_tokens')->sole())->toBe($before)
        ->and($this->recoveryPort->links)->toBe([])->and(DB::transactionLevel())->toBe(0);
});

it('sanitizes a real SQL insert failure and rolls back its preceding token deletion', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    app(PasswordBrokerManager::class)->broker('users')->getRepository()->create($user);
    $before = (array) DB::table('password_reset_tokens')->sole();
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:01:00 UTC'));
    DB::statement('ALTER TABLE password_reset_tokens ADD CONSTRAINT recovery_test_reject CHECK (false) NOT VALID');

    try {
        try {
            $this->useCase->execute('maria@example.com');
            $this->fail('The check constraint must reject issuance.');
        } catch (RuntimeException $exception) {
            expect($exception->getMessage())->toBe('Não foi possível persistir a recuperação de senha.')
                ->and($exception->getPrevious())->toBeNull();
        }
        expect((array) DB::table('password_reset_tokens')->sole())->toBe($before)
            ->and($this->recoveryPort->links)->toBe([])->and(DB::transactionLevel())->toBe(0);
    } finally {
        DB::statement('ALTER TABLE password_reset_tokens DROP CONSTRAINT recovery_test_reject');
    }
});

it('does not issue without delivery availability even for an eligible account', function (): void {
    IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->recoveryPort->available = false;

    $this->useCase->execute('maria@example.com');

    expect(DB::table('password_reset_tokens')->count())->toBe(0)->and($this->recoveryPort->links)->toBe([]);
});

it('refuses uncoordinated writes outside the use case transaction', function (): void {
    expect(fn () => app(PasswordRecoveryRepository::class)->issue(EmailValueObject::fromString('maria@example.com')))
        ->toThrow(LogicException::class, 'A emissão de recuperação exige uma transação ativa.');
    expect(DB::table('password_reset_tokens')->count())->toBe(0);
});

it('refuses a native repository on a different connection before any recovery write', function (): void {
    config(['database.connections.recovery_other' => config('database.connections.pgsql'), 'auth.passwords.users.connection' => 'recovery_other']);

    expect(fn () => $this->useCase->execute('maria@example.com'))
        ->toThrow(LogicException::class, 'A recuperação exige a mesma conexão de persistência da conta.');
    expect(DB::table('password_reset_tokens')->count())->toBe(0)->and($this->recoveryPort->links)->toBe([]);
});
