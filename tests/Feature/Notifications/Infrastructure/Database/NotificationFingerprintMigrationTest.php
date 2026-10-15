<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Tests\Support\Identity\Fixtures\IdentityFixture;
use Tests\Support\Notifications\Fixtures\NotificationRegistrationFixture;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-13 12:00:00 UTC'));
});

it('recalculates existing fingerprints without changing encrypted destinations or lifecycle metadata', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $bearer = IdentityFixture::token($user, now()->addDays(20));
    $id = $this->withToken($bearer)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertCreated()->json('data.id');
    DB::table('notifications')->where('id', $id)->update(['identifier_fingerprint' => str_repeat('a', 64)]);
    $before = (array) DB::table('notifications')->where('id', $id)->first();
    $migration = require database_path('migrations/2026_10_13_224125_recalculate_notification_fingerprints.php');

    $migration->up();

    $after = (array) DB::table('notifications')->where('id', $id)->first();
    expect($after)->toBe([...$before, 'identifier_fingerprint' => hash('sha256', "fcm\0token\0FakeFcmToken:AbC_123")]);
    Auth::forgetGuards();
    $this->withToken($bearer)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertOk()->assertJsonPath('data.id', $id);
    expect(DB::table('notifications')->count())->toBe(1);
});

it('rolls back earlier fingerprint writes if a later destination cannot be decrypted', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $bearer = IdentityFixture::token($user, now()->addDays(20));
    $first = $this->withToken($bearer)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertCreated()->json('data.id');
    Auth::forgetGuards();
    $second = $this->withToken($bearer)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload(NotificationRegistrationFixture::OtherInstallation, 'second-fake-token'))->assertCreated()->json('data.id');
    DB::table('notifications')->where('id', $first)->update(['id' => NotificationRegistrationFixture::Registration, 'identifier_fingerprint' => str_repeat('a', 64)]);
    DB::table('notifications')->where('id', $second)->update([
        'id' => NotificationRegistrationFixture::OtherRegistration,
        'identifier_fingerprint' => str_repeat('b', 64),
        'registration_identifier' => 'invalid-ciphertext-sentinel',
    ]);
    $before = DB::table('notifications')->orderBy('id')->get()->all();
    $migration = require database_path('migrations/2026_10_13_224125_recalculate_notification_fingerprints.php');
    DB::enableQueryLog();

    try {
        $migration->up();
        $this->fail('Expected failure on the second encrypted destination.');
    } catch (RuntimeException $exception) {
        $writes = array_values(array_filter(DB::getQueryLog(), static fn (array $query): bool => str_starts_with($query['query'], 'update "notifications"')));
        expect($exception->getPrevious())->toBeNull()
            ->and($exception->getMessage())->toBe('Não foi possível recalcular os fingerprints; nenhuma alteração foi confirmada.')
            ->and($writes)->toHaveCount(1)
            ->and($writes[0]['bindings'][0])->toBe(hash('sha256', "fcm\0token\0FakeFcmToken:AbC_123"))
            ->and($writes[0]['bindings'][1])->toBe(NotificationRegistrationFixture::Registration)
            ->and(DB::table('notifications')->orderBy('id')->get()->all())->toEqual($before);
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }
});
