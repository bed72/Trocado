<?php

declare(strict_types=1);

use App\Identity\Application\Repositories\EmailVerificationRepository;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\EloquentEmailVerificationRepository;
use Illuminate\Auth\Events\Verified;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Notification;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('persists confirmation under lock without emitting events or notifications', function (): void {
    Event::fake([Verified::class]);
    Notification::fake();
    $user = IdentityFixture::create(status: UserStatusEnum::Pending, verifiedAt: null);
    $repository = app(EmailVerificationRepository::class);
    expect($repository)->toBeInstanceOf(EloquentEmailVerificationRepository::class);
    DB::enableQueryLog();
    DB::flushQueryLog();

    try {
        $first = DB::transaction(fn () => $repository->verify($user->getKey(), sha1($user->email)));
        $queries = DB::getQueryLog();
    } finally {
        DB::disableQueryLog();
    }

    $verifiedAt = $user->refresh()->email_verified_at;
    expect($first->isValid)->toBeTrue()->and($first->wasVerifiedNow)->toBeTrue()
        ->and($verifiedAt)->not->toBeNull()
        ->and($queries[0]['query'])->toContain('for update')
        ->and($user->status)->toBe(UserStatusEnum::Pending)
        ->and($user->tokens()->count())->toBe(0);

    $second = DB::transaction(fn () => $repository->verify($user->getKey(), sha1($user->email)));
    expect($second->isValid)->toBeTrue()->and($second->wasVerifiedNow)->toBeFalse()
        ->and($user->refresh()->email_verified_at->equalTo($verifiedAt))->toBeTrue();
    Event::assertNotDispatched(Verified::class);
    Notification::assertNothingSent();
});

it('rejects a missing identity or a hash for a different email without changing state', function (bool $missing): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Pending, verifiedAt: null);
    $id = $user->getKey();

    if ($missing) {
        $user->delete();
    }

    $output = DB::transaction(fn () => app(EmailVerificationRepository::class)->verify($id, sha1('other@example.com')));
    expect($output->isValid)->toBeFalse()->and($output->wasVerifiedNow)->toBeFalse();

    if (! $missing) {
        expect($user->refresh()->email_verified_at)->toBeNull();
    }
})->with(['missing' => true, 'wrong hash' => false]);
