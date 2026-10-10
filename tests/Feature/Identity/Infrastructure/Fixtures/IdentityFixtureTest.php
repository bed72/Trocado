<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Notifications\VerifyEmailNotification;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\Support\Identity\Fixtures\IdentityFixture;
use Tests\Support\Identity\Helpers\IdentityHttpJourney;

it('creates only the explicit account state without tokens notifications or a replacement fake', function (UserStatusEnum $status, bool $verified): void {
    $notificationFake = Notification::fake();
    $verifiedAt = $verified ? new DateTimeImmutable('2026-01-01T12:00:00+00:00') : null;
    $user = IdentityFixture::create(status: $status, verifiedAt: $verifiedAt, password: ' Correct1 ');

    expect($user->fresh()->status)->toBe($status)
        ->and($user->fresh()->email_verified_at?->format(DATE_ATOM))->toBe($verifiedAt?->format(DATE_ATOM))
        ->and($user->tokens()->count())->toBe(0)
        ->and(Hash::check(' Correct1 ', $user->password))->toBeTrue()
        ->and(Notification::getFacadeRoot())->toBe($notificationFake);
    Notification::assertNothingSent();
})->with(UserStatusEnum::cases())->with([false, true]);

it('prepares a real bearer token with explicit expiry without calling login', function (): void {
    $this->travelTo(new DateTimeImmutable('2026-10-10T12:00:00+00:00'));
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $expiresAt = new DateTimeImmutable('2026-11-09T12:00:00+00:00');
    $token = IdentityFixture::token($user, expiresAt: $expiresAt);
    $record = PersonalAccessToken::findToken($token);

    expect($record->tokenable_id)->toBe($user->getKey())
        ->and($record->expires_at->equalTo($expiresAt))->toBeTrue()
        ->and($record->token)->toBe(hash('sha256', explode('|', $token, 2)[1]));
    $this->withToken($token)->getJson(route('users.get', ['user' => $user->getKey()]))->assertOk();
});

it('keeps the HTTP registration and verification journey pending until activation is explicitly arranged', function (): void {
    $notificationFake = Notification::fake();
    $journey = new IdentityHttpJourney($this);
    $userId = $journey->signUp();
    $user = UserModel::query()->findOrFail($userId);

    expect($user->status)->toBe(UserStatusEnum::Pending)->and($user->email_verified_at)->toBeNull()
        ->and($user->tokens()->count())->toBe(0)->and(Notification::getFacadeRoot())->toBe($notificationFake);
    Notification::assertSentTo($user, VerifyEmailNotification::class, 1);

    $journey->verifyEmail($user, expiresAt: now()->addHour());
    expect($user->fresh()->status)->toBe(UserStatusEnum::Pending)
        ->and($user->fresh()->email_verified_at)->not->toBeNull()
        ->and($user->tokens()->count())->toBe(0);

    $user->update(['status' => UserStatusEnum::Active]);
    $token = $journey->signIn();
    expect(PersonalAccessToken::findToken($token)->tokenable_id)->toBe($userId);
});
