<?php

declare(strict_types=1);

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Data\Input\ResetPasswordInput;
use App\Identity\Application\Data\Output\SignInOutput;
use App\Identity\Application\Exceptions\InvalidCredentialsException;
use App\Identity\Application\Repositories\PasswordRecoveryRepository;
use App\Identity\Application\UseCases\RequestPasswordRecoveryUseCase;
use App\Identity\Application\UseCases\ResetPasswordUseCase;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Adapters\SessionAdapter;
use App\Identity\Infrastructure\Adapters\SignInAdapter;
use App\Identity\Infrastructure\Repositories\Persistence\Models\PersonalAccessTokenModel;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\Support\Core\Fixtures\ConcurrentDatabaseProcess;
use Tests\Support\Identity\Fixtures\IdentityFixture;
use Tests\Support\Identity\Spies\PasswordRecoveryPortSpy;
use Tests\Support\Identity\Spies\PasswordResetPortSpy;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00 UTC'));
    $this->owner = IdentityFixture::create(UserStatusEnum::Active, now());
    $this->bearer = IdentityFixture::token($this->owner, now()->addDays(30), 'first-device');
    $this->secondBearer = IdentityFixture::token($this->owner, now()->addDays(30), 'second-device');
    $this->other = IdentityFixture::create(UserStatusEnum::Active, now(), email: 'other@example.com');
    $this->otherBearer = IdentityFixture::token($this->other, now()->addDays(30));
    $this->otherToken = PersonalAccessTokenModel::findToken($this->otherBearer)->getRawOriginal();
    $this->travelTo(CarbonImmutable::parse('2026-01-17 12:00:00 UTC'));
    $port = new PasswordRecoveryPortSpy;
    (new RequestPasswordRecoveryUseCase(app(TransactionPort::class), $port, app(PasswordRecoveryRepository::class)))
        ->execute('maria@example.com');
    $this->input = new ResetPasswordInput('maria@example.com', $port->links[0]['token'], 'Newpass1');
    $this->notices = new PasswordResetPortSpy;
    $this->reset = new ResetPasswordUseCase(resetPort: $this->notices, transactionPort: app(TransactionPort::class), repository: app(PasswordRecoveryRepository::class));
});

afterEach(function (): void {
    Auth::forgetGuards();
});

it('rechecks an old credential after waiting for a competing reset instead of issuing or rehashing it', function (): void {
    $ownerId = $this->owner->getKey();
    $child = new ConcurrentDatabaseProcess(static function () use ($ownerId): void {
        DB::statement('SET statement_timeout = 4000');
        expect(fn () => app(SignInAdapter::class)->issue(' MARIA@EXAMPLE.COM ', 'Correct1'))
            ->toThrow(InvalidCredentialsException::class);
        expect(UserModel::query()->findOrFail($ownerId)->tokens()->count())->toBe(0)
            ->and(Hash::check('Newpass1', UserModel::query()->findOrFail($ownerId)->password))->toBeTrue()
            ->and(DB::transactionLevel())->toBe(0);
    });

    try {
        app(TransactionPort::class)->commit(function () use ($child): void {
            DB::statement('SET LOCAL statement_timeout = 4000');
            $this->reset->execute($this->input);
            $child->go();
            $child->awaitLock();
            expect(DB::selectOne('select pg_blocking_pids(?)::text as blockers', [$child->backendPid])->blockers)
                ->toBe('{'.DB::selectOne('select pg_backend_pid() as pid')->pid.'}');
        });
        $child->done();

        expect($this->owner->tokens()->count())->toBe(0)
            ->and(DB::table('password_reset_tokens')->count())->toBe(0)
            ->and($this->notices->notices)->toHaveCount(1)
            ->and(Hash::check('Correct1', $this->owner->fresh()->password))->toBeFalse()
            ->and(PersonalAccessTokenModel::findToken($this->otherBearer)->getRawOriginal())->toBe($this->otherToken);
        $newSession = app(SignInAdapter::class)->issue('maria@example.com', 'Newpass1');
        expect(PersonalAccessTokenModel::findToken($newSession->token)->getKey())->toBe($newSession->id)
            ->and($this->owner->tokens()->count())->toBe(1);
    } finally {
        $child->close();
    }
})->group('concurrency', 'integration');

it('revokes a login admitted before the competing reset without leaving a late PAT', function (): void {
    $input = $this->input;
    $ownerId = $this->owner->getKey();
    $child = new ConcurrentDatabaseProcess(static function () use ($input, $ownerId): void {
        DB::statement('SET statement_timeout = 4000');
        $port = new PasswordResetPortSpy;
        (new ResetPasswordUseCase(resetPort: $port, transactionPort: app(TransactionPort::class), repository: app(PasswordRecoveryRepository::class)))
            ->execute($input);
        expect($port->notices)->toHaveCount(1)
            ->and(UserModel::query()->findOrFail($ownerId)->tokens()->count())->toBe(0)
            ->and(DB::transactionLevel())->toBe(0);
    });

    try {
        $session = DB::transaction(function () use ($child): SignInOutput {
            DB::statement('SET LOCAL statement_timeout = 4000');
            $session = app(SignInAdapter::class)->issue('maria@example.com', 'Correct1');
            expect($this->owner->tokens()->count())->toBe(3)
                ->and(PersonalAccessTokenModel::findToken($session->token))->not->toBeNull();
            $child->go();
            $child->awaitLock();
            expect(DB::selectOne('select pg_blocking_pids(?)::text as blockers', [$child->backendPid])->blockers)
                ->toBe('{'.DB::selectOne('select pg_backend_pid() as pid')->pid.'}');

            return $session;
        });
        $child->done();

        expect(PersonalAccessTokenModel::findToken($session->token))->toBeNull()
            ->and($this->owner->tokens()->count())->toBe(0)
            ->and(DB::table('password_reset_tokens')->count())->toBe(0)
            ->and(Hash::check('Newpass1', $this->owner->fresh()->password))->toBeTrue()
            ->and(PersonalAccessTokenModel::findToken($this->otherBearer)->getRawOriginal())->toBe($this->otherToken);
        expect(fn () => app(SignInAdapter::class)->issue('maria@example.com', 'Correct1'))
            ->toThrow(InvalidCredentialsException::class);
    } finally {
        $child->close();
    }
})->group('concurrency', 'integration');

it('does not revive a renewing PAT when a reset commits while renewal waits', function (): void {
    $principal = $this->owner->fresh()->withAccessToken(PersonalAccessTokenModel::findToken($this->bearer));
    $child = new ConcurrentDatabaseProcess(static function () use ($principal): void {
        DB::statement('SET statement_timeout = 4000');
        Auth::forgetGuards();
        Auth::guard('sanctum')->setUser($principal);
        app(SessionAdapter::class)->extendCurrentToken();
        expect($principal->tokens()->count())->toBe(0)->and(DB::transactionLevel())->toBe(0);
    });

    try {
        app(TransactionPort::class)->commit(function () use ($child): void {
            DB::statement('SET LOCAL statement_timeout = 4000');
            $this->reset->execute($this->input);
            $child->go();
            $child->awaitLock();
            expect(DB::selectOne('select pg_blocking_pids(?)::text as blockers', [$child->backendPid])->blockers)
                ->toBe('{'.DB::selectOne('select pg_backend_pid() as pid')->pid.'}');
        });
        $child->done();

        expect(PersonalAccessTokenModel::findToken($this->bearer))->toBeNull()
            ->and(PersonalAccessTokenModel::findToken($this->secondBearer))->toBeNull()
            ->and($this->owner->tokens()->count())->toBe(0)
            ->and(PersonalAccessTokenModel::findToken($this->otherBearer)->getRawOriginal())->toBe($this->otherToken)
            ->and($this->notices->notices)->toHaveCount(1);
        Auth::forgetGuards();
        $this->withToken($this->bearer)->getJson(route('users.get', ['user' => $this->owner->getKey()]))->assertUnauthorized();
    } finally {
        $child->close();
    }
})->group('concurrency', 'integration');

it('removes a PAT already renewed by a competing transaction without undoing the reset', function (): void {
    $principal = $this->owner->fresh()->withAccessToken(PersonalAccessTokenModel::findToken($this->bearer));
    Auth::guard('sanctum')->setUser($principal);
    $input = $this->input;
    $ownerId = $this->owner->getKey();
    $child = new ConcurrentDatabaseProcess(static function () use ($input, $ownerId): void {
        DB::statement('SET statement_timeout = 4000');
        $port = new PasswordResetPortSpy;
        (new ResetPasswordUseCase(resetPort: $port, transactionPort: app(TransactionPort::class), repository: app(PasswordRecoveryRepository::class)))
            ->execute($input);
        expect(UserModel::query()->findOrFail($ownerId)->tokens()->count())->toBe(0)
            ->and($port->notices)->toHaveCount(1)->and(DB::transactionLevel())->toBe(0);
    });

    try {
        DB::transaction(function () use ($child): void {
            DB::statement('SET LOCAL statement_timeout = 4000');
            app(SessionAdapter::class)->extendCurrentToken();
            expect(PersonalAccessTokenModel::findToken($this->bearer)->expires_at->equalTo(now()->addDays(30)))->toBeTrue();
            $child->go();
            $child->awaitLock();
            expect(DB::selectOne('select pg_blocking_pids(?)::text as blockers', [$child->backendPid])->blockers)
                ->toBe('{'.DB::selectOne('select pg_backend_pid() as pid')->pid.'}');
        });
        $child->done();

        expect(PersonalAccessTokenModel::findToken($this->bearer))->toBeNull()
            ->and(PersonalAccessTokenModel::findToken($this->secondBearer))->toBeNull()
            ->and(Hash::check('Newpass1', $this->owner->fresh()->password))->toBeTrue()
            ->and(DB::table('password_reset_tokens')->count())->toBe(0)
            ->and(PersonalAccessTokenModel::findToken($this->otherBearer)->getRawOriginal())->toBe($this->otherToken);
        Auth::forgetGuards();
        Auth::guard('sanctum')->setUser($principal);
        app(SessionAdapter::class)->extendCurrentToken();
        expect($this->owner->tokens()->count())->toBe(0);
    } finally {
        $child->close();
    }
})->group('concurrency', 'integration');
