<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\PersonalAccessTokenModel as PersonalAccessToken;
use App\Notifications\Infrastructure\Repositories\Persistence\Models\NotificationModel;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\Support\Core\Fixtures\ConcurrentDatabaseProcess;
use Tests\Support\Identity\Fixtures\IdentityFixture;
use Tests\Support\Notifications\Fixtures\NotificationRegistrationFixture;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-13 12:00:00 UTC'));
});

it('serializes concurrent first registrations through session locks or database uniqueness', function (string $dispute): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, now());
    $parentToken = IdentityFixture::token($owner, now()->addDays(20));
    $childOwner = $dispute === 'other account' ? IdentityFixture::create(UserStatusEnum::Active, now(), email: 'other@example.com') : $owner;
    $childToken = $dispute === 'same session' ? $parentToken : IdentityFixture::token($childOwner, now()->addDays(20));
    $test = $this;
    $child = new ConcurrentDatabaseProcess(static function () use ($test, $childToken, $dispute): void {
        Auth::forgetGuards();
        $response = $test->withToken($childToken)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())
            ->assertStatus($dispute === 'other account' ? 409 : 200);
        expect(DB::table('notifications')->count())->toBe(1);
        if ($dispute !== 'other account') {
            $response->assertJsonPath('data.id', DB::table('notifications')->value('id'));
        }
    });

    try {
        $id = DB::transaction(function () use ($child, $parentToken): string {
            Auth::forgetGuards();
            $id = $this->withToken($parentToken)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertCreated()->json('data.id');
            $child->go();
            $child->awaitLock();

            return $id;
        });
        $child->done();
        expect(DB::table('notifications')->count())->toBe(1)
            ->and(Str::isUuid($id, version: 7))->toBeTrue()
            ->and($id)->not->toBe(NotificationRegistrationFixture::Installation)
            ->and(NotificationModel::query()->find($id)->user_id)->toBe($owner->getKey())
            ->and(NotificationModel::query()->find($id)->generation)->toBe($dispute === 'same owner new session' ? 2 : 1);
    } finally {
        $child->close();
    }
})->with(['same session', 'same owner new session', 'other account'])->group('concurrency', 'integration');

it('serializes competing rotations and commits coherent monotonically versioned state', function (): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, now());
    $parentToken = IdentityFixture::token($owner, now()->addDays(20));
    $childToken = IdentityFixture::token($owner, now()->addDays(20));
    $id = $this->withToken($parentToken)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertCreated()->json('data.id');
    $test = $this;
    $child = new ConcurrentDatabaseProcess(static function () use ($test, $childToken, $id): void {
        Auth::forgetGuards();
        $test->withToken($childToken)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload(identifier: 'child-rotation', platform: 'ios'))
            ->assertOk()->assertJsonPath('data.id', $id);
    });

    try {
        DB::transaction(function () use ($child, $parentToken, $id): void {
            Auth::forgetGuards();
            $this->withToken($parentToken)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload(identifier: 'parent-rotation'))
                ->assertOk()->assertJsonPath('data.id', $id);
            $child->go();
            $child->awaitLock();
        });
        $child->done();
        $current = NotificationModel::query()->find($id);
        expect($current->generation)->toBe(3)->and($current->registration_identifier)->toBe('child-rotation')
            ->and(Str::isUuid($current->getKey(), version: 7))->toBeTrue()
            ->and($current->identifier_fingerprint)->toBe(hash('sha256', "fcm\0token\0child-rotation"))
            ->and($current->platform)->toBe('ios')
            ->and($current->session_id)->toBe(PersonalAccessToken::findToken($childToken)->getKey())
            ->and(DB::table('notifications')->count())->toBe(1);
    } finally {
        $child->close();
    }
})->group('concurrency', 'integration');

it('does not recreate registrations while sign-out competes with registration', function (bool $logoutFirst): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, now());
    $token = IdentityFixture::token($owner, now()->addDays(20));
    $test = $this;
    $child = new ConcurrentDatabaseProcess(static function () use ($test, $token, $logoutFirst): void {
        Auth::forgetGuards();
        if ($logoutFirst) {
            $test->withToken($token)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertUnauthorized();
        } else {
            $test->withToken($token)->deleteJson(route('authentication.api.sign-out'))->assertNoContent();
        }
    });

    try {
        DB::transaction(function () use ($child, $token, $logoutFirst): void {
            Auth::forgetGuards();
            if ($logoutFirst) {
                $this->withToken($token)->deleteJson(route('authentication.api.sign-out'))->assertNoContent();
            } else {
                $this->withToken($token)->postJson('/api/push-registrations', NotificationRegistrationFixture::payload())->assertCreated();
            }
            $child->go();
            $child->awaitLock();
        });
        $child->done();
        expect(DB::table('notifications')->count())->toBe(0)
            ->and(PersonalAccessToken::findToken($token))->toBeNull();
    } finally {
        $child->close();
    }
})->with(['logout first' => true, 'registration first' => false])->group('concurrency', 'integration');
