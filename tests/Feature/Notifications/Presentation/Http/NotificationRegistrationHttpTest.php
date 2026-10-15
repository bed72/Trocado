<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\PersonalAccessTokenModel as PersonalAccessToken;
use App\Notifications\Infrastructure\Repositories\Persistence\Models\NotificationModel;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Tests\Support\Identity\Fixtures\IdentityFixture;
use Tests\Support\Notifications\Fixtures\NotificationRegistrationFixture;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-13 12:00:00 UTC'));
});

it('keeps two installations independent and synchronizes then rotates one without duplicates', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $token = IdentityFixture::token($user, now()->addDays(20));
    $session = PersonalAccessToken::findToken($token);
    $expiry = $session->expires_at->format(DATE_ATOM);
    $first = $this->withToken($token)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())
        ->assertCreated()->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('data.type', 'push-registrations');
    $id = $first->json('data.id');
    $originalCiphertext = DB::table('notifications')->where('id', $id)->value('registration_identifier');

    expect($first->headers->get('Cache-Control'))->toContain('no-store')
        ->and($first->headers->has('Location'))->toBeFalse()
        ->and(array_keys($first->json('data.attributes')))->toBe(['installation_id', 'platform', 'provider', 'last_registered_at']);

    Auth::forgetGuards();
    $this->withToken($token)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload(NotificationRegistrationFixture::OtherInstallation, 'OtherFakeToken', 'ios'))->assertCreated();
    $this->travelTo(now()->addHour());
    Auth::forgetGuards();
    $this->withToken($token)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertOk()->assertJsonPath('data.id', $id);
    expect(NotificationModel::query()->count())->toBe(2)
        ->and(NotificationModel::query()->find($id)->generation)->toBe(1)
        ->and(DB::table('notifications')->where('id', $id)->value('registration_identifier'))->toBe($originalCiphertext);

    Auth::forgetGuards();
    $this->withToken($token)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload(identifier: 'RotatedFakeToken'))
        ->assertOk()->assertJsonPath('data.id', $id)->assertDontSee('RotatedFakeToken');
    $current = NotificationModel::query()->find($id);
    expect($current->registration_identifier)->toBe('RotatedFakeToken')->and($current->generation)->toBe(2)
        ->and(NotificationModel::query()->count())->toBe(2)
        ->and($session->fresh()->expires_at->format(DATE_ATOM))->toBe($expiry)
        ->and($user->tokens()->count())->toBe(1)
        ->and(DB::table('notifications')->where('id', $id)->value('registration_identifier'))->not->toBe('RotatedFakeToken');
});

it('rejects installation or destination takeover and duplicate destinations within the same account', function (): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, now());
    $other = IdentityFixture::create(UserStatusEnum::Active, now(), email: 'other@example.com');
    $ownerToken = IdentityFixture::token($owner, now()->addDays(20));
    $otherToken = IdentityFixture::token($other, now()->addDays(20));
    $id = $this->withToken($ownerToken)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertCreated()->json('data.id');

    foreach ([
        [$otherToken, NotificationRegistrationFixture::payload(identifier: 'another-token')],
        [$otherToken, NotificationRegistrationFixture::payload(NotificationRegistrationFixture::OtherInstallation)],
        [$ownerToken, NotificationRegistrationFixture::payload(NotificationRegistrationFixture::OtherInstallation)],
    ] as [$token, $payload]) {
        Auth::forgetGuards();
        $this->withToken($token)->postJson('/api/push-registrations', $payload)->assertConflict()
            ->assertHeader('Content-Type', 'application/vnd.api+json')->assertDontSee('FakeFcmToken');
    }

    expect(NotificationModel::query()->count())->toBe(1)
        ->and(NotificationModel::query()->find($id)->user_id)->toBe($owner->getKey())
        ->and(NotificationModel::query()->find($id)->generation)->toBe(1);
});

it('deletes only owned registration and gives uniform not found responses', function (): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, now());
    $other = IdentityFixture::create(UserStatusEnum::Active, now(), email: 'other@example.com');
    $token = IdentityFixture::token($owner, now()->addDays(20));
    $otherToken = IdentityFixture::token($other, now()->addDays(20));
    $id = $this->withToken($token)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertCreated()->json('data.id');
    Auth::forgetGuards();
    $otherResponse = $this->withToken($otherToken)->deleteJson('/api/push-registrations/'.$id)->assertNotFound()->json();
    expect(NotificationModel::query()->count())->toBe(1);
    Auth::forgetGuards();
    $this->withToken($token)->deleteJson('/api/push-registrations/'.$id)->assertNoContent();

    foreach ([$id, 'not-a-uuid', NotificationRegistrationFixture::OtherInstallation] as $missing) {
        Auth::forgetGuards();
        $this->withToken($token)->deleteJson('/api/push-registrations/'.$missing)->assertNotFound()->assertExactJson($otherResponse);
    }
    expect(PersonalAccessToken::findToken($token))->not->toBeNull()
        ->and(PersonalAccessToken::findToken($otherToken))->not->toBeNull();
});

it('requires real valid bearer credentials', function (string $credential): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $token = match ($credential) {
        'expired' => IdentityFixture::token($user, now()->subSecond()),
        'revoked' => IdentityFixture::token($user, now()->addDays(20)),
        'invalid' => 'not-a-token',
        default => '',
    };
    if ($credential === 'revoked') {
        $user->tokens()->delete();
    }
    $this->withToken($token)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertUnauthorized();
    Auth::forgetGuards();
    $this->withToken($token)->deleteJson('/api/push-registrations/'.NotificationRegistrationFixture::Installation)->assertUnauthorized();
    expect(NotificationModel::query()->count())->toBe(0);
})->with(['missing', 'invalid', 'expired', 'revoked']);

it('requires active verified accounts', function (UserStatusEnum $status, bool $verified): void {
    $user = IdentityFixture::create($status, $verified ? now() : null);
    $token = IdentityFixture::token($user, now()->addDays(20));
    $this->withToken($token)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertForbidden();
    expect(NotificationModel::query()->count())->toBe(0);
})->with([[UserStatusEnum::Pending, true], [UserStatusEnum::Blocked, true], [UserStatusEnum::Active, false]]);

it('rejects invalid closed document fields with pointers without echoing the destination', function (string $field, mixed $value): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $token = IdentityFixture::token($user, now()->addDays(20));
    $payload = NotificationRegistrationFixture::payload();
    data_set($payload, $field, $value);
    $response = $this->withToken($token)->postJson('/api/push-registrations', $payload)->assertUnprocessable();
    expect(array_column(array_column($response->json('errors'), 'source'), 'pointer'))->toContain('/'.str_replace('.', '/', $field))
        ->and($response->getContent())->not->toContain('FakeFcmToken')
        ->and(NotificationModel::query()->count())->toBe(0);
})->with([
    ['data.attributes.registration_identifier', ' token '],
    ['data.attributes.registration_identifier', "token\n"],
    ['data.attributes.registration_identifier', 'tóken'],
    ['data.attributes.registration_identifier', str_repeat('a', 4097)],
    ['data.attributes.registration_identifier', null],
    ['data.attributes.registration_identifier', 123],
    ['data.attributes.installation_id', 'device-id'],
    ['data.attributes.platform', 'web'],
    ['data.attributes.registration_kind', 'fid'],
    ['data.attributes.user_id', 999],
    ['data.attributes.session_id', 999],
    ['data.attributes.provider', 'fcm'],
    ['data.attributes.generation', 1],
    ['data.attributes.last_registered_at', '2026-10-13'],
    ['data.id', 'arbitrary'],
    ['data.relationships', []],
    ['unexpected', 'FakeFcmToken'],
]);

it('moves a registration to a new session of the same owner and sign-out remains selective', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $oldToken = IdentityFixture::token($user, now()->addDays(20));
    $newToken = IdentityFixture::token($user, now()->addDays(20));
    $id = $this->withToken($oldToken)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertCreated()->json('data.id');
    Auth::forgetGuards();
    $this->withToken($oldToken)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload(NotificationRegistrationFixture::OtherInstallation, 'another-token'))->assertCreated();
    Auth::forgetGuards();
    $this->withToken($newToken)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertOk()->assertJsonPath('data.id', $id);
    Auth::forgetGuards();
    $this->withToken($oldToken)->deleteJson(route('authentication.api.sign-out'))->assertNoContent();
    expect(NotificationModel::query()->count())->toBe(1)
        ->and(NotificationModel::query()->find($id)->generation)->toBe(2);
    Auth::forgetGuards();
    $this->withToken($newToken)->deleteJson(route('authentication.api.sign-out'))->assertNoContent();
    expect(NotificationModel::query()->count())->toBe(0);
});

it('preserves exact identifier bytes including case and the input limit', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $token = IdentityFixture::token($user, now()->addDays(20));
    $identifier = 'AbC:'.str_repeat('x', 4092);
    $id = $this->withToken($token)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload(identifier: $identifier))->assertCreated()->json('data.id');
    expect(NotificationModel::query()->find($id)->registration_identifier)->toBe($identifier);
});

it('uses the shared authenticated quota without extra tokens or IP granting another quota', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $token = IdentityFixture::token($user, now()->addDays(20));
    $other = IdentityFixture::token($user, now()->addDays(20));
    for ($attempt = 0; $attempt < 60; $attempt++) {
        Auth::forgetGuards();
        $this->withToken($token)->getJson('/api/users/'.$user->getKey())->assertOk();
    }
    Auth::forgetGuards();
    $this->withToken($other)->withServerVariables(['REMOTE_ADDR' => '192.0.2.1'])
        ->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertTooManyRequests()->assertHeader('Retry-After');
    expect(NotificationModel::query()->count())->toBe(0);
});

it('does not expose a list or a sending endpoint', function (): void {
    $this->getJson('/api/push-registrations')->assertStatus(405);
    $this->postJson('/api/push-notifications', [])->assertNotFound();
});
