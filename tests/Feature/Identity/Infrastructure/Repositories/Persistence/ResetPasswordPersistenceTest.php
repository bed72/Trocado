<?php

declare(strict_types=1);

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Data\Input\ResetPasswordInput;
use App\Identity\Application\Exceptions\CurrentPasswordException;
use App\Identity\Application\Exceptions\InvalidPasswordRecoveryException;
use App\Identity\Application\Ports\PasswordResetPort;
use App\Identity\Application\Repositories\PasswordRecoveryRepository;
use App\Identity\Application\UseCases\RequestPasswordRecoveryUseCase;
use App\Identity\Application\UseCases\ResetPasswordUseCase;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\PasswordValueObject;
use App\Identity\Infrastructure\Repositories\Persistence\EloquentPasswordRecoveryRepository;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Passwords\PasswordBrokerManager;
use Illuminate\Contracts\Config\Repository;
use Illuminate\Contracts\Database\ConcurrencyErrorDetector;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Tests\Support\Identity\Fixtures\IdentityFixture;
use Tests\Support\Identity\Spies\PasswordRecoveryPortSpy;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:00 UTC'));
    Notification::fake();
    $this->user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->pat = IdentityFixture::token($this->user, expiresAt: now()->addDay());
    IdentityFixture::token($this->user, expiresAt: now()->addDays(2), name: 'second-device');
    $this->other = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'other@example.com');
    IdentityFixture::token($this->other, expiresAt: now()->addDay());
    $this->links = new PasswordRecoveryPortSpy;
    $this->request = new RequestPasswordRecoveryUseCase(app(TransactionPort::class), $this->links, app(PasswordRecoveryRepository::class));
    $this->request->execute('maria@example.com');
    $this->token = $this->links->links[0]['token'];
    $this->notice = $this->createMock(PasswordResetPort::class);
    $this->reset = new ResetPasswordUseCase(app(TransactionPort::class), $this->notice, app(PasswordRecoveryRepository::class));
});

it('updates only the password consumes the recovery and revokes every owner PAT without issuing a session', function (string $password): void {
    $before = $this->user->fresh()->getRawOriginal();
    $otherUser = $this->other->fresh()->getRawOriginal();
    $otherTokens = DB::table('personal_access_tokens')->where('tokenable_id', $this->other->getKey())->get()->all();
    $this->notice->expects($this->once())->method('requestNotice')->with($this->user->getKey(), 'maria@example.com')
        ->willReturnCallback(function (): void {
            expect(DB::transactionLevel())->toBe(0)->and(DB::table('password_reset_tokens')->count())->toBe(0)
                ->and($this->user->tokens()->count())->toBe(0);
        });

    DB::enableQueryLog();
    DB::flushQueryLog();
    try {
        $result = $this->reset->execute(new ResetPasswordInput(' MARIA@EXAMPLE.COM ', $this->token, $password));
        $queries = array_column(DB::getQueryLog(), 'query');
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }

    $after = $this->user->fresh()->getRawOriginal();
    expect($result)->toBeNull()->and($queries[0])->toContain('"users"', 'for update')
        ->and($queries[1])->toContain('"password_reset_tokens"', 'for update')
        ->and(Hash::check($password, $after['password']))->toBeTrue()
        ->and(Hash::check('Correct1', $after['password']))->toBeFalse();
    unset($before['password'], $before['updated_at'], $after['password'], $after['updated_at']);
    expect($after)->toBe($before)->and($this->other->fresh()->getRawOriginal())->toBe($otherUser)
        ->and(DB::table('personal_access_tokens')->get()->all())->toEqual($otherTokens);
    expect(fn () => $this->reset->execute(new ResetPasswordInput('maria@example.com', $this->token, 'Another1')))
        ->toThrow(InvalidPasswordRecoveryException::class);
    Notification::assertNothingSent();
})->with(['minimum' => 'Abcd12', 'maximum characters' => 'A1'.str_repeat('b', 30), '72 bytes unicode uppercase' => 'Á1'.str_repeat('😀', 17).' ', 'spaces' => ' Nova1 ']);

it('rejects the current password without any writes and permits another password using the same link', function (): void {
    $before = [DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()];
    $this->notice->expects($this->once())->method('requestNotice');
    expect(fn () => $this->reset->execute(new ResetPasswordInput('maria@example.com', $this->token, 'Correct1')))
        ->toThrow(CurrentPasswordException::class);
    expect([DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()])->toEqual($before);
    $this->reset->execute(new ResetPasswordInput('maria@example.com', $this->token, 'Different1'));
});

it('enforces the inclusive thirty minute boundary', function (string $time, bool $valid): void {
    $this->travelTo(CarbonImmutable::parse($time));
    $input = new ResetPasswordInput('maria@example.com', $this->token, 'Different1');
    if ($valid) {
        $this->notice->expects($this->once())->method('requestNotice');
        $this->reset->execute($input);
        expect($this->user->tokens()->count())->toBe(0);
    } else {
        $this->notice->expects($this->never())->method('requestNotice');
        expect(fn () => $this->reset->execute($input))->toThrow(InvalidPasswordRecoveryException::class);
        expect(Hash::check('Correct1', $this->user->fresh()->password))->toBeTrue()
            ->and($this->user->tokens()->count())->toBe(2)->and(DB::table('password_reset_tokens')->count())->toBe(1);
    }
})->with(['before' => ['2026-10-21 12:29:59.999999 UTC', true], 'exact' => ['2026-10-21 12:30:00 UTC', false], 'after' => ['2026-10-21 12:30:00.000001 UTC', false]]);

it('revalidates eligibility and rejects obsolete credentials without effects', function (string $change): void {
    match ($change) {
        'pending' => $this->user->forceFill(['status' => UserStatusEnum::Pending])->save(),
        'blocked' => $this->user->forceFill(['status' => UserStatusEnum::Blocked])->save(),
        'unverified' => $this->user->forceFill(['email_verified_at' => null])->save(),
        'address' => $this->user->forceFill(['email' => 'new@example.com'])->save(),
        'removed' => $this->user->delete(),
        'missing token' => DB::table('password_reset_tokens')->delete(),
        'missing timestamp' => DB::table('password_reset_tokens')->update(['created_at' => null]),
        'invalid timestamp' => DB::table('password_reset_tokens')->update(['created_at' => 'infinity']),
        'wrong token' => $this->token = 'incorrect-token',
        'token spaces' => $this->token = ' '.$this->token.' ',
        'rotated' => (function (): void {
            $this->travelTo(CarbonImmutable::parse('2026-10-21 12:01:00 UTC'));
            $this->request->execute('maria@example.com');
        })(),
    };
    $before = [DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()];
    $this->notice->expects($this->never())->method('requestNotice');

    expect(fn () => $this->reset->execute(new ResetPasswordInput('maria@example.com', $this->token, 'Correct1')))
        ->toThrow(InvalidPasswordRecoveryException::class);
    expect([DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()])->toEqual($before);
})->with(['pending', 'blocked', 'unverified', 'address', 'removed', 'missing token', 'missing timestamp', 'invalid timestamp', 'wrong token', 'token spaces', 'rotated']);

it('restores hash recovery and real PATs and discards a registered notice on a sentinel rollback', function (): void {
    $before = [DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()];
    $failure = new RuntimeException('reset-rollback-sentinel');
    $this->notice->expects($this->never())->method('requestNotice');
    try {
        app(TransactionPort::class)->commit(function () use ($failure): never {
            $this->reset->execute(new ResetPasswordInput('maria@example.com', $this->token, 'Different1'));
            expect(Hash::check('Different1', $this->user->fresh()->password))->toBeTrue()
                ->and($this->user->tokens()->count())->toBe(0)->and(DB::table('password_reset_tokens')->count())->toBe(0);
            throw $failure;
        });
        $this->fail('Expected the sentinel.');
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($failure);
    }
    expect([DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()])->toEqual($before);
    $this->notice = $this->createMock(PasswordResetPort::class);
    $this->notice->expects($this->once())->method('requestNotice');
    (new ResetPasswordUseCase(app(TransactionPort::class), $this->notice, app(PasswordRecoveryRepository::class)))
        ->execute(new ResetPasswordInput('maria@example.com', $this->token, 'Different1'));
});

it('sanitizes SQL failure after changing the hash and rolls the write back', function (): void {
    $before = [DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()];
    $this->notice->expects($this->never())->method('requestNotice');
    DB::unprepared("CREATE FUNCTION reset_test_fail() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'reset-delete-sentinel'; END $$");
    DB::unprepared('CREATE TRIGGER reset_test_fail BEFORE DELETE ON password_reset_tokens FOR EACH ROW EXECUTE FUNCTION reset_test_fail()');
    try {
        try {
            $this->reset->execute(new ResetPasswordInput('maria@example.com', $this->token, 'Different1'));
            $this->fail('Expected SQL failure.');
        } catch (RuntimeException $exception) {
            expect($exception->getMessage())->toBe('Não foi possível persistir a recuperação de senha.')
                ->and($exception->getPrevious())->toBeNull();
            $trace = $exception->getTraceAsString();
            expect($trace)->not->toContain('Different1', $this->token, $this->user->password, 'reset-delete-sentinel');
        }
        expect([DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()])->toEqual($before);
    } finally {
        DB::unprepared('DROP TRIGGER reset_test_fail ON password_reset_tokens');
        DB::unprepared('DROP FUNCTION reset_test_fail()');
    }
});

it('refuses a reset outside the transaction or using a divergent native connection', function (): void {
    expect(fn () => app(PasswordRecoveryRepository::class)->reset(EmailValueObject::fromString('maria@example.com'), $this->token, PasswordValueObject::fromString('Different1')))
        ->toThrow(LogicException::class, 'A redefinição exige uma transação ativa.');
    config(['database.connections.recovery_other' => config('database.connections.pgsql'), 'auth.passwords.users.connection' => 'recovery_other']);
    $repository = new EloquentPasswordRecoveryRepository(app(Repository::class), new PasswordBrokerManager(app()), app(ConcurrencyErrorDetector::class));
    $useCase = new ResetPasswordUseCase(app(TransactionPort::class), $this->notice, $repository);
    expect(fn () => $useCase->execute(new ResetPasswordInput('maria@example.com', $this->token, 'Different1')))
        ->toThrow(LogicException::class, 'A recuperação exige a mesma conexão de persistência da conta.');
});

it('redacts a failed password UPDATE including its bindings with exception arguments enabled', function (): void {
    $before = [DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()];
    $this->notice->expects($this->never())->method('requestNotice');
    $previousSetting = ini_get('zend.exception_ignore_args');
    ini_set('zend.exception_ignore_args', '0');
    DB::statement('ALTER TABLE users ADD CONSTRAINT reset_test_reject CHECK (false) NOT VALID');
    try {
        try {
            $this->reset->execute(new ResetPasswordInput('maria@example.com', $this->token, 'Different1'));
            $this->fail('Expected password update failure.');
        } catch (RuntimeException $exception) {
            expect($exception->getMessage())->toBe('Não foi possível persistir a recuperação de senha.')
                ->and($exception->getPrevious())->toBeNull()
                ->and((string) $exception)->not->toContain('Different1', $this->token, $this->user->password, 'update "users"', 'reset_test_reject');
        }
        expect([DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()])->toEqual($before);
    } finally {
        DB::statement('ALTER TABLE users DROP CONSTRAINT reset_test_reject');
        ini_set('zend.exception_ignore_args', $previousSetting);
    }
});
