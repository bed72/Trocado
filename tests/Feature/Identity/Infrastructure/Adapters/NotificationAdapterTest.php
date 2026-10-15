<?php

declare(strict_types=1);

use App\Identity\Application\Exceptions\InactiveUserException;
use App\Identity\Application\Exceptions\UnverifiedEmailException;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Adapters\NotificationAdapter;
use App\Notifications\Application\Ports\NotificationPort;
use DateTimeImmutable as ReferenceInstant;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('locks and returns the canonical UUID PAT for the current owner without extending it', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $session = $user->createToken('notification', ['*'], now()->addDays(30))->accessToken;
    Auth::guard('sanctum')->setUser($user->withAccessToken($session));
    $port = app(NotificationPort::class);
    expect($port)->toBeInstanceOf(NotificationAdapter::class);
    DB::enableQueryLog();
    DB::flushQueryLog();
    try {
        $id = DB::transaction(fn () => $port->lock(strtoupper($user->id), new ReferenceInstant));
        $queries = DB::getQueryLog();
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }
    expect($id)->toBe($session->id)->and($queries[0]['query'])->toContain('for update')
        ->and($session->fresh()->expires_at->equalTo($session->expires_at))->toBeTrue();
});

it('revalidates the persisted owner session and account after the guard snapshot', function (string $change, string $exceptionClass): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $session = $user->createToken('notification', ['*'], now()->addDays(30))->accessToken;
    Auth::guard('sanctum')->setUser($user->withAccessToken($session));
    match ($change) {
        'owner' => DB::table('personal_access_tokens')->where('id', $session->id)->update(['tokenable_id' => UuidFixture::at(999)]),
        'morph' => DB::table('personal_access_tokens')->where('id', $session->id)->update(['tokenable_type' => 'unknown']),
        'expired' => DB::table('personal_access_tokens')->where('id', $session->id)->update(['expires_at' => now()->subSecond()]),
        'maximum_age' => DB::table('personal_access_tokens')->where('id', $session->id)->update(['created_at' => now()->subDays(91)]),
        'deleted' => DB::table('personal_access_tokens')->where('id', $session->id)->delete(),
        'blocked' => DB::table('users')->where('id', $user->id)->update(['status' => 'blocked']),
        'unverified' => DB::table('users')->where('id', $user->id)->update(['email_verified_at' => null]),
    };
    expect(fn () => DB::transaction(fn () => app(NotificationPort::class)->lock($user->id, new ReferenceInstant)))
        ->toThrow($exceptionClass);
})->with([
    'owner' => ['owner', AuthenticationException::class], 'morph' => ['morph', AuthenticationException::class],
    'expired' => ['expired', AuthenticationException::class], 'maximum age' => ['maximum_age', AuthenticationException::class],
    'deleted' => ['deleted', AuthenticationException::class], 'blocked' => ['blocked', InactiveUserException::class],
    'unverified' => ['unverified', UnverifiedEmailException::class],
]);
