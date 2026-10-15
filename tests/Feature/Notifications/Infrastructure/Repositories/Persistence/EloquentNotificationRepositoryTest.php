<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\PersonalAccessTokenModel as PersonalAccessToken;
use App\Notifications\Application\Data\Input\RegisterNotificationRegistrationInput;
use App\Notifications\Application\UseCases\CreateNotificationUseCase;
use App\Notifications\Domain\Enums\NotificationPlatformEnum;
use App\Notifications\Domain\ValueObjects\NotificationValueObject;
use App\Notifications\Infrastructure\Repositories\Persistence\EloquentNotificationRepository;
use App\Notifications\Infrastructure\Repositories\Persistence\Models\NotificationModel;
use Carbon\CarbonImmutable;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;
use Tests\Support\Notifications\Fixtures\NotificationRegistrationFixture;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-13 12:00:00 UTC'));
});

it('stores encrypted exact destinations with deterministic SHA256 fingerprints and hidden attributes', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $bearer = IdentityFixture::token($user, now()->addDays(20));
    $sessionId = PersonalAccessToken::findToken($bearer)->getKey();
    $repository = app(EloquentNotificationRepository::class);
    $destination = new NotificationValueObject(
        installationId: NotificationRegistrationFixture::Installation,
        registrationKind: 'token',
        platform: NotificationPlatformEnum::Android,
        identifier: 'AbC:def-123',
    );
    $registration = DB::transaction(fn () => $repository->create($user->getKey(), $sessionId, $destination, new DateTimeImmutable('2026-10-13T09:00:00-03:00')));
    $raw = DB::table('notifications')->where('id', $registration->id)->first();
    $model = NotificationModel::query()->find($registration->id);
    $mapped = DB::transaction(fn () => $repository->lock($destination));

    expect($raw->registration_identifier)->not->toBe('AbC:def-123')
        ->and($raw->identifier_fingerprint)->toBe(hash('sha256', "fcm\0token\0AbC:def-123"))
        ->and($model->registration_identifier)->toBe('AbC:def-123')
        ->and($model->last_registered_at->utc()->format(DATE_ATOM))->toBe('2026-10-13T12:00:00+00:00')
        ->and($model->toArray())->not->toHaveKeys(['registration_identifier', 'identifier_fingerprint', 'session_id', 'generation', 'user_id'])
        ->and($mapped)->toHaveCount(1)
        ->and($mapped[0]->id)->toBe($registration->id)
        ->and($mapped[0]->sessionId)->toBe($sessionId)
        ->and($mapped[0]->generation)->toBe(1)
        ->and($mapped[0]->destination->identifier)->toBe('AbC:def-123');
});

it('enforces database uniqueness and closed value constraints independently of application checks', function (string $field, mixed $value): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $bearer = IdentityFixture::token($user, now()->addDays(20));
    $id = $this->withToken($bearer)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertCreated()->json('data.id');
    $raw = (array) DB::table('notifications')->where('id', $id)->first();
    $duplicate = [...$raw, 'id' => NotificationRegistrationFixture::OtherInstallation,
        'installation_id' => NotificationRegistrationFixture::OtherInstallation, 'identifier_fingerprint' => str_repeat('b', 64), $field => $value];

    expect(fn () => DB::transaction(fn () => DB::table('notifications')->insert($duplicate)))->toThrow(QueryException::class)
        ->and(DB::table('notifications')->count())->toBe(1);
})->with([
    ['installation_id', NotificationRegistrationFixture::Installation],
    ['identifier_fingerprint', hash('sha256', "fcm\0token\0FakeFcmToken:AbC_123")],
    ['platform', 'web'], ['registration_kind', 'fid'], ['provider', 'apns'], ['generation', 0],
]);

it('rolls back a rotation that fails after its database write and discards after-commit events', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $bearer = IdentityFixture::token($user, now()->addDays(20));
    $id = $this->withToken($bearer)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertCreated()->json('data.id');
    $before = (array) DB::table('notifications')->where('id', $id)->first();
    $sentinel = new RuntimeException('rotation-write-sentinel');
    $listener = static function (NotificationModel $model) use ($sentinel): void {
        expect(DB::table('notifications')->where('id', $model->getKey())->value('generation'))->toBe(2);
        throw $sentinel;
    };
    app('events')->listen('eloquent.updated: '.NotificationModel::class, $listener);
    $observability = $this->createMock(ObservabilityPort::class);
    $observability->expects($this->never())->method('emit');
    $this->app->instance(ObservabilityPort::class, $observability);
    Auth::forgetGuards();
    Auth::guard('sanctum')->setUser($user->withAccessToken(PersonalAccessToken::findToken($bearer)));

    try {
        app(CreateNotificationUseCase::class)->execute(new RegisterNotificationRegistrationInput(
            registeredAt: new DateTimeImmutable('2026-10-13T13:00:00Z'),
            destination: new NotificationValueObject(installationId: NotificationRegistrationFixture::Installation, registrationKind: 'token', platform: NotificationPlatformEnum::Ios, identifier: 'rotated-token'),
        ));
        $this->fail('Expected the post-write sentinel.');
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($sentinel)
            ->and((array) DB::table('notifications')->where('id', $id)->first())->toBe($before);
    } finally {
        app('events')->forget('eloquent.updated: '.NotificationModel::class);
    }
});

it('removes all registrations on account deletion through cascades', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $bearer = IdentityFixture::token($user, now()->addDays(20));
    $this->withToken($bearer)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertCreated();
    DB::transaction(fn () => $user->delete());
    expect(DB::table('notifications')->count())->toBe(0);
});

it('emits only allowed registration metadata after a real commit and tolerates logger failure', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $bearer = IdentityFixture::token($user, now()->addDays(20));
    $observability = $this->createMock(ObservabilityPort::class);
    $observability->expects($this->once())->method('emit')->with('push.registration.created', $this->callback(function (array $attributes): bool {
        expect(DB::transactionLevel())->toBe(0)
            ->and(array_keys($attributes))->toBe(['user_id', 'registration_id', 'platform', 'generation'])
            ->and(DB::table('notifications')->where('id', $attributes['registration_id'])->exists())->toBeTrue();

        return true;
    }))->willThrowException(new RuntimeException('logger-unavailable'));
    $this->app->instance(ObservabilityPort::class, $observability);
    $this->withToken($bearer)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertCreated();
    expect(DB::table('notifications')->count())->toBe(1);
});

it('registers and rotates destinations without a secondary secret', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $bearer = IdentityFixture::token($user, now()->addDays(20));
    $id = $this->withToken($bearer)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertCreated()->json('data.id');
    Auth::forgetGuards();
    $this->withToken($bearer)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload(identifier: 'new-fake-token'))
        ->assertOk()->assertJsonPath('data.id', $id)->assertDontSee('new-fake-token');

    expect(DB::table('notifications')->count())->toBe(1)
        ->and(DB::table('notifications')->where('id', $id)->value('identifier_fingerprint'))->toBe(hash('sha256', "fcm\0token\0new-fake-token"))
        ->and(NotificationModel::query()->find($id)->registration_identifier)->toBe('new-fake-token');
});

it('revalidates session and account state inside the transaction instead of trusting the guard snapshot', function (string $change): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $bearer = IdentityFixture::token($user, now()->addDays(20));
    $session = PersonalAccessToken::findToken($bearer);
    Auth::guard('sanctum')->setUser($user->withAccessToken($session));
    match ($change) {
        'revoked' => $session->delete(),
        'expired' => $session->forceFill(['expires_at' => now()->subSecond()])->save(),
        'ownership' => $session->forceFill(['tokenable_id' => UuidFixture::at(999)])->save(),
        'blocked' => DB::table('users')->where('id', $user->getKey())->update(['status' => 'blocked']),
        'unverified' => DB::table('users')->where('id', $user->getKey())->update(['email_verified_at' => null]),
    };
    $this->withToken($bearer)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())
        ->assertStatus(in_array($change, ['blocked', 'unverified'], true) ? 403 : 401);
    expect(DB::table('notifications')->count())->toBe(0);
})->with(['revoked', 'expired', 'ownership', 'blocked', 'unverified']);
