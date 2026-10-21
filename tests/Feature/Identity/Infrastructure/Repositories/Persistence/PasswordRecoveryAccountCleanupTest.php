<?php

declare(strict_types=1);

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Application\UseCases\DeleteUserUseCase;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Auth\Passwords\PasswordBrokerManager;
use Illuminate\Support\Facades\DB;
use Tests\Support\Core\Spies\ObservabilityPortSpy;
use Tests\Support\Core\Stubs\UserPortStub;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('locks the account before removing its recovery and sessions and does not transfer a link to a new account', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $other = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'other@example.com');
    IdentityFixture::token($user, expiresAt: now()->addDay());
    IdentityFixture::token($other, expiresAt: now()->addDay());
    $tokens = app(PasswordBrokerManager::class)->broker('users')->getRepository();
    $oldToken = $tokens->create($user);
    $otherToken = $tokens->create($other);
    $otherRecovery = (array) DB::table('password_reset_tokens')->where('email', $other->email)->sole();
    $otherSessions = DB::table('personal_access_tokens')->where('tokenable_id', $other->getKey())->get()->all();
    $observability = new ObservabilityPortSpy;
    $useCase = new DeleteUserUseCase(new UserPortStub($user->getKey()), app(TransactionPort::class), $observability, app(UserRepository::class));

    DB::enableQueryLog();
    DB::flushQueryLog();
    try {
        $useCase->execute($user->getKey());
        $queries = array_column(DB::getQueryLog(), 'query');
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }

    expect($queries[0])->toContain('"users"', 'for update')
        ->and($queries[1])->toContain('delete from "password_reset_tokens"')
        ->and($queries[2])->toContain('delete from "personal_access_tokens"')
        ->and($queries[3])->toContain('delete from "users"')
        ->and(DB::table('users')->where('id', $user->getKey())->exists())->toBeFalse()
        ->and(DB::table('personal_access_tokens')->where('tokenable_id', $user->getKey())->exists())->toBeFalse()
        ->and(DB::table('password_reset_tokens')->where('email', $user->email)->exists())->toBeFalse()
        ->and((array) DB::table('password_reset_tokens')->where('email', $other->email)->sole())->toBe($otherRecovery)
        ->and(DB::table('personal_access_tokens')->where('tokenable_id', $other->getKey())->get()->all())->toEqual($otherSessions)
        ->and($tokens->exists($other, $otherToken))->toBeTrue()
        ->and($observability->events)->toBe([['event' => 'user.deleted', 'attributes' => ['user_id' => $user->getKey()]]]);

    $replacement = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    expect($replacement->getKey())->not->toBe($user->getKey())
        ->and($tokens->exists($replacement, $oldToken))->toBeFalse();
});

it('rolls recovery sessions and account back together after a sentinel failure following the real deletion', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    IdentityFixture::token($user, expiresAt: now()->addDay());
    app(PasswordBrokerManager::class)->broker('users')->getRepository()->create($user);
    $before = [];
    foreach (['users', 'personal_access_tokens', 'password_reset_tokens'] as $table) {
        $before[$table] = DB::table($table)->get()->all();
    }
    $failure = new RuntimeException('account-cleanup-rollback-sentinel');
    $realRepository = app(UserRepository::class);
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('delete')->with($user->getKey())
        ->willReturnCallback(function (string $id) use ($realRepository, $failure): never {
            expect(DB::transactionLevel())->toBe(1)
                ->and($realRepository->delete($id))->toBeTrue();
            foreach (['users', 'personal_access_tokens', 'password_reset_tokens'] as $table) {
                expect(DB::table($table)->count())->toBe(0);
            }
            throw $failure;
        });
    $observability = new ObservabilityPortSpy;
    $useCase = new DeleteUserUseCase(new UserPortStub($user->getKey()), app(TransactionPort::class), $observability, $repository);

    try {
        $useCase->execute($user->getKey());
        $this->fail('The sentinel must leave the transaction as a failure.');
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($failure);
    }

    foreach ($before as $table => $rows) {
        expect(DB::table($table)->get()->all())->toEqual($rows);
    }
    expect(DB::transactionLevel())->toBe(0)->and($observability->events)->toBe([]);
});
