<?php

declare(strict_types=1);

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Data\Input\ResetPasswordInput;
use App\Identity\Application\Exceptions\InvalidPasswordRecoveryException;
use App\Identity\Application\Repositories\PasswordRecoveryRepository;
use App\Identity\Application\UseCases\RequestPasswordRecoveryUseCase;
use App\Identity\Application\UseCases\ResetPasswordUseCase;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Passwords\PasswordBrokerManager;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\Support\Core\Fixtures\ConcurrentDatabaseProcess;
use Tests\Support\Identity\Fixtures\IdentityFixture;
use Tests\Support\Identity\Spies\PasswordRecoveryPortSpy;
use Tests\Support\Identity\Spies\PasswordResetPortSpy;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:00 UTC'));
    $this->owner = IdentityFixture::create(UserStatusEnum::Active, now());
    IdentityFixture::token($this->owner, now()->addDay(), 'first-device');
    IdentityFixture::token($this->owner, now()->addDays(2), 'second-device');
    $this->other = IdentityFixture::create(UserStatusEnum::Active, now(), email: 'other@example.com');
    IdentityFixture::token($this->other, now()->addDay());
    $this->otherState = $this->other->fresh()->getRawOriginal();
    $this->otherTokens = $this->other->tokens()->get()->map->getRawOriginal()->all();
    $this->links = new PasswordRecoveryPortSpy;
    $this->notices = new PasswordResetPortSpy;
    $this->request = new RequestPasswordRecoveryUseCase(app(TransactionPort::class), $this->links, app(PasswordRecoveryRepository::class));
    $this->reset = new ResetPasswordUseCase(transactionPort: app(TransactionPort::class), resetPort: $this->notices, repository: app(PasswordRecoveryRepository::class));
});

it('admits one emission when a second process contends for the same canonical address', function (bool $rotate): void {
    $oldToken = null;
    if ($rotate) {
        $this->request->execute('maria@example.com');
        $oldToken = $this->links->links[0]['token'];
        $this->links->links = [];
        $this->travelTo(CarbonImmutable::parse('2026-10-21 12:01:00 UTC'));
    }
    $beforeUser = $this->owner->fresh()->getRawOriginal();
    $beforeTokens = DB::table('personal_access_tokens')->orderBy('id')->get()->all();
    $child = new ConcurrentDatabaseProcess(static function (): void {
        DB::statement('SET statement_timeout = 4000');
        $port = new PasswordRecoveryPortSpy;
        (new RequestPasswordRecoveryUseCase(app(TransactionPort::class), $port, app(PasswordRecoveryRepository::class)))
            ->execute(' MARIA@EXAMPLE.COM ');
        expect($port->links)->toBe([])->and(DB::table('password_reset_tokens')->count())->toBe(1)
            ->and(DB::transactionLevel())->toBe(0);
    });

    try {
        app(TransactionPort::class)->commit(function () use ($child): void {
            DB::statement('SET LOCAL statement_timeout = 4000');
            $this->request->execute('maria@example.com');
            expect($this->links->links)->toBe([]);
            $child->go();
            $child->awaitLock();
            expect(DB::selectOne('select pg_blocking_pids(?)::text as blockers', [$child->backendPid])->blockers)
                ->toBe('{'.DB::selectOne('select pg_backend_pid() as pid')->pid.'}');
        });
        $child->done();

        $record = (array) DB::table('password_reset_tokens')->sole();
        expect($this->links->links)->toHaveCount(1)
            ->and($record['email'])->toBe('maria@example.com')
            ->and($record['created_at'])->toBe($rotate ? '2026-10-21 12:01:00' : '2026-10-21 12:00:00')
            ->and(Hash::check($this->links->links[0]['token'], $record['token']))->toBeTrue()
            ->and($this->owner->fresh()->getRawOriginal())->toBe($beforeUser)
            ->and(DB::table('personal_access_tokens')->orderBy('id')->get()->all())->toEqual($beforeTokens);
        if ($rotate) {
            expect(app(PasswordBrokerManager::class)->broker('users')->getRepository()->exists($this->owner, $oldToken))->toBeFalse();
        }
    } finally {
        $child->close();
    }
})->with(['first emission without a recovery row' => false, 'rotation of an existing token' => true])->group('concurrency', 'integration');

it('allows only one reset and one notice when two processes consume the same token', function (): void {
    $this->request->execute('maria@example.com');
    $token = $this->links->links[0]['token'];
    $ownerId = $this->owner->getKey();
    $child = new ConcurrentDatabaseProcess(static function () use ($token, $ownerId): void {
        DB::statement('SET statement_timeout = 4000');
        $port = new PasswordResetPortSpy;
        $useCase = new ResetPasswordUseCase(transactionPort: app(TransactionPort::class), resetPort: $port, repository: app(PasswordRecoveryRepository::class));
        expect(fn () => $useCase->execute(new ResetPasswordInput('maria@example.com', $token, 'Child1')))
            ->toThrow(InvalidPasswordRecoveryException::class);
        expect($port->notices)->toBe([])->and(DB::transactionLevel())->toBe(0)
            ->and(Hash::check('Parent1', UserModel::query()->findOrFail($ownerId)->password))->toBeTrue();
    });

    try {
        app(TransactionPort::class)->commit(function () use ($child, $token): void {
            DB::statement('SET LOCAL statement_timeout = 4000');
            $this->reset->execute(new ResetPasswordInput(' MARIA@EXAMPLE.COM ', $token, 'Parent1'));
            expect($this->notices->notices)->toBe([]);
            $child->go();
            $child->awaitLock();
            expect(DB::selectOne('select pg_blocking_pids(?)::text as blockers', [$child->backendPid])->blockers)
                ->toBe('{'.DB::selectOne('select pg_backend_pid() as pid')->pid.'}');
        });
        $child->done();

        $user = $this->owner->fresh();
        expect(Hash::check('Parent1', $user->password))->toBeTrue()
            ->and(Hash::check('Child1', $user->password))->toBeFalse()
            ->and(Hash::check('Correct1', $user->password))->toBeFalse()
            ->and($user->tokens()->count())->toBe(0)
            ->and(DB::table('password_reset_tokens')->count())->toBe(0)
            ->and($this->notices->notices)->toBe([['user_id' => $ownerId, 'email' => 'maria@example.com']])
            ->and($this->other->fresh()->getRawOriginal())->toBe($this->otherState)
            ->and($this->other->tokens()->get()->map->getRawOriginal()->all())->toBe($this->otherTokens);
    } finally {
        $child->close();
    }
})->group('concurrency', 'integration');

it('rejects a waiting consumer of the old token after a competing rotation commits', function (): void {
    $this->request->execute('maria@example.com');
    $oldToken = $this->links->links[0]['token'];
    $this->links->links = [];
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:01:00 UTC'));
    $before = DB::table('personal_access_tokens')->orderBy('id')->get()->all();
    $child = new ConcurrentDatabaseProcess(static function () use ($oldToken): void {
        DB::statement('SET statement_timeout = 4000');
        $port = new PasswordResetPortSpy;
        $useCase = new ResetPasswordUseCase(transactionPort: app(TransactionPort::class), resetPort: $port, repository: app(PasswordRecoveryRepository::class));
        expect(fn () => $useCase->execute(new ResetPasswordInput('maria@example.com', $oldToken, 'Child1')))
            ->toThrow(InvalidPasswordRecoveryException::class);
        expect($port->notices)->toBe([])->and(DB::table('password_reset_tokens')->count())->toBe(1);
    });

    try {
        app(TransactionPort::class)->commit(function () use ($child): void {
            DB::statement('SET LOCAL statement_timeout = 4000');
            $this->request->execute('maria@example.com');
            $child->go();
            $child->awaitLock();
            expect(DB::selectOne('select pg_blocking_pids(?)::text as blockers', [$child->backendPid])->blockers)
                ->toBe('{'.DB::selectOne('select pg_backend_pid() as pid')->pid.'}');
        });
        $child->done();

        expect($this->links->links)->toHaveCount(1)
            ->and(Hash::check('Correct1', $this->owner->fresh()->password))->toBeTrue()
            ->and(DB::table('personal_access_tokens')->orderBy('id')->get()->all())->toEqual($before)
            ->and($this->notices->notices)->toBe([]);
        $newToken = $this->links->links[0]['token'];
        expect(Hash::check($newToken, DB::table('password_reset_tokens')->sole()->token))->toBeTrue();
        $this->reset->execute(new ResetPasswordInput('maria@example.com', $newToken, 'Parent1'));
        expect(DB::table('password_reset_tokens')->count())->toBe(0)
            ->and($this->notices->notices)->toHaveCount(1)->and($this->owner->tokens()->count())->toBe(0);
    } finally {
        $child->close();
    }
})->group('concurrency', 'integration');

it('lets a waiting issuer create a new recovery after the competing reset consumes the old one', function (): void {
    $this->request->execute('maria@example.com');
    $oldToken = $this->links->links[0]['token'];
    $ownerId = $this->owner->getKey();
    $child = new ConcurrentDatabaseProcess(static function () use ($oldToken, $ownerId): void {
        DB::statement('SET statement_timeout = 4000');
        $port = new PasswordRecoveryPortSpy;
        (new RequestPasswordRecoveryUseCase(app(TransactionPort::class), $port, app(PasswordRecoveryRepository::class)))
            ->execute(' MARIA@EXAMPLE.COM ');
        $native = app(PasswordBrokerManager::class)->broker('users')->getRepository();
        $user = UserModel::query()->findOrFail($ownerId);
        expect($port->links)->toHaveCount(1)->and(DB::table('password_reset_tokens')->count())->toBe(1)
            ->and($native->exists($user, $oldToken))->toBeFalse()
            ->and($native->exists($user, $port->links[0]['token']))->toBeTrue()
            ->and(Hash::check('Parent1', $user->password))->toBeTrue()
            ->and($user->tokens()->count())->toBe(0)->and(DB::transactionLevel())->toBe(0);
    });

    try {
        app(TransactionPort::class)->commit(function () use ($child, $oldToken): void {
            DB::statement('SET LOCAL statement_timeout = 4000');
            $this->reset->execute(new ResetPasswordInput('maria@example.com', $oldToken, 'Parent1'));
            expect($this->notices->notices)->toBe([]);
            $child->go();
            $child->awaitLock();
            expect(DB::selectOne('select pg_blocking_pids(?)::text as blockers', [$child->backendPid])->blockers)
                ->toBe('{'.DB::selectOne('select pg_backend_pid() as pid')->pid.'}');
        });
        $child->done();

        $record = DB::table('password_reset_tokens')->sole();
        expect($record->email)->toBe('maria@example.com')->and($record->created_at)->toBe('2026-10-21 12:00:00')
            ->and(Hash::check($oldToken, $record->token))->toBeFalse()
            ->and($this->notices->notices)->toBe([['user_id' => $ownerId, 'email' => 'maria@example.com']])
            ->and($this->owner->tokens()->count())->toBe(0)
            ->and($this->other->fresh()->getRawOriginal())->toBe($this->otherState)
            ->and($this->other->tokens()->get()->map->getRawOriginal()->all())->toBe($this->otherTokens);
        expect(fn () => $this->reset->execute(new ResetPasswordInput('maria@example.com', $oldToken, 'Child1')))
            ->toThrow(InvalidPasswordRecoveryException::class);
        expect(DB::table('password_reset_tokens')->count())->toBe(1);
    } finally {
        $child->close();
    }
})->group('concurrency', 'integration');
