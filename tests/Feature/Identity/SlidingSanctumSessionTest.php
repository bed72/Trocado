<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Adapters\SessionAdapter;
use App\Identity\Infrastructure\Repositories\Persistence\Models\PersonalAccessTokenModel as PersonalAccessToken;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Carbon\CarbonImmutable;
use Illuminate\Database\Events\TransactionBeginning;
use Illuminate\Database\Events\TransactionCommitted;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Illuminate\Testing\TestResponse;
use Tests\Support\Core\Fixtures\ConcurrentDatabaseProcess;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Core\Fixtures\UuidSchemaFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;
use Tests\Support\Identity\Helpers\IdentityHttpJourney;

use function Pest\Laravel\withToken;

function sessionRequest(string $token, string $route, array $parameters = []): TestResponse
{
    Auth::forgetGuards();

    return withToken($token)->getJson(route($route, $parameters));
}

it('keeps official last-used tracking and distinguishes same-second from next-second writes', function (): void {
    $reference = CarbonImmutable::parse('2026-01-01 12:00:00');
    $this->travelTo($reference);
    $user = IdentityFixture::create(UserStatusEnum::Active, $reference);
    $token = IdentityFixture::token($user, $reference->addDays(30));
    $connection = DB::connection();
    $wasLogging = $connection->logging();
    $reads = [];
    $writes = [];
    $connection->enableQueryLog();

    try {
        foreach ([0, 0, 1] as $seconds) {
            $this->travelTo($reference->addSeconds($seconds));
            $connection->flushQueryLog();
            sessionRequest($token, 'users.get', ['user' => $user->id])->assertOk();
            $queries = $connection->getQueryLog();
            $reads[] = count(array_filter($queries, static fn (array $query): bool => str_contains($query['query'], 'from "personal_access_tokens"')));
            $writes[] = count(array_filter($queries, static fn (array $query): bool => str_starts_with($query['query'], 'update "personal_access_tokens"')
                && str_contains($query['query'], '"last_used_at"')));
        }
    } finally {
        $connection->flushQueryLog();
        if (! $wasLogging) {
            $connection->disableQueryLog();
        }
    }

    expect(config('sanctum.last_used_at'))->toBeTrue()
        ->and($reads)->toBe([2, 2, 2])
        ->and($writes)->toBe([1, 0, 1])
        ->and(PersonalAccessToken::findToken($token)->last_used_at->equalTo($reference->addSecond()))->toBeTrue();
});

it('opens the renewal transaction only after a fresh read indicates an extension', function (int $days, bool $eligible): void {
    $reference = CarbonImmutable::parse('2026-01-01 12:00:00');
    $this->travelTo($reference);
    $user = IdentityFixture::create(UserStatusEnum::Active, $reference);
    $token = IdentityFixture::token($user, $reference->addDays(30));
    $this->travel($days)->days();
    sessionRequest($token, 'users.get', ['user' => UuidFixture::at(999)])->assertNotFound();
    $connection = DB::connection();
    $wasLogging = $connection->logging();
    $dispatcher = Event::getFacadeRoot();
    $connectionDispatcher = $connection->getEventDispatcher();
    Event::fake([TransactionBeginning::class, TransactionCommitted::class]);
    $connection->setEventDispatcher(Event::getFacadeRoot());
    $connection->enableQueryLog();
    $connection->flushQueryLog();

    try {
        app(SessionAdapter::class)->extendCurrentToken();
        $queries = $connection->getQueryLog();
        expect($queries)->toHaveCount($eligible ? 3 : 1)
            ->and(array_filter($queries, static fn (array $query): bool => str_contains($query['query'], 'for update')))->toHaveCount($eligible ? 1 : 0)
            ->and(array_filter($queries, static fn (array $query): bool => str_starts_with($query['query'], 'update ')))->toHaveCount($eligible ? 1 : 0);
        Event::assertDispatchedTimes(TransactionBeginning::class, $eligible ? 1 : 0);
        Event::assertDispatchedTimes(TransactionCommitted::class, $eligible ? 1 : 0);
    } finally {
        $connection->setEventDispatcher($connectionDispatcher);
        Event::swap($dispatcher);
        $connection->flushQueryLog();
        if (! $wasLogging) {
            $connection->disableQueryLog();
        }
    }
})->with(['outside window' => [1, false], 'within window' => [16, true]]);

it('uses the writer connection for the fresh eligibility read', function (): void {
    $reference = CarbonImmutable::parse('2026-01-01 12:00:00');
    $this->travelTo($reference);
    $user = IdentityFixture::create(UserStatusEnum::Active, $reference);
    $token = IdentityFixture::token($user, $reference->addDays(30));
    sessionRequest($token, 'users.get', ['user' => UuidFixture::at(999)])->assertNotFound();
    $connection = DB::connection();
    $readPdo = $connection->getRawReadPdo();
    $readCalls = 0;
    $connection->setReadPdo(static function () use (&$readCalls): never {
        $readCalls++;
        throw new RuntimeException('A replica cannot decide renewal eligibility.');
    });

    try {
        app(SessionAdapter::class)->extendCurrentToken();
        expect($readCalls)->toBe(0)->and($connection->transactionLevel())->toBe(0);
    } finally {
        $connection->setReadPdo($readPdo);
    }
});

it('does not use the authenticated model dates after persistence changes', function (string $change): void {
    $reference = CarbonImmutable::parse('2026-01-01 12:00:00');
    $this->travelTo($reference);
    $user = IdentityFixture::create(UserStatusEnum::Active, $reference);
    $token = IdentityFixture::token($user, $reference->addDays(30));
    $this->travel(1)->days();
    sessionRequest($token, 'users.get', ['user' => UuidFixture::at(999)])->assertNotFound();
    $authenticated = Auth::guard('sanctum')->user()->currentAccessToken();
    $expected = match ($change) {
        'shorten' => now()->toImmutable()->addDays(30),
        'extend' => $reference->addDays(60),
        'expire' => now()->toImmutable()->subSecond(),
        'revoke' => null,
    };

    if ($change === 'revoke') {
        PersonalAccessToken::query()->whereKey($authenticated->id)->delete();
    } else {
        PersonalAccessToken::query()->whereKey($authenticated->id)->update([
            'expires_at' => $change === 'shorten' ? now()->addDays(2) : $expected,
        ]);
    }

    expect($authenticated->expires_at->equalTo($reference->addDays(30)))->toBeTrue();
    app(SessionAdapter::class)->extendCurrentToken();
    $persisted = $authenticated->fresh();

    if ($change === 'revoke') {
        expect($persisted)->toBeNull();
    } else {
        expect($persisted->expires_at->equalTo($expected))->toBeTrue();
    }
    if (in_array($change, ['expire', 'revoke'], true)) {
        sessionRequest($token, 'users.get', ['user' => $user->id])->assertUnauthorized();
    }
})->with(['shorten', 'extend', 'expire', 'revoke']);

it('issues a single expiring Sanctum token and keeps its bearer and hash on fortnightly activity', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now())->getKey();
    $token = (new IdentityHttpJourney($this))->signIn();
    $user = UserModel::query()->findOrFail($userId);
    $record = $user->tokens()->sole();
    $id = $record->getKey();
    $digest = $record->token;
    $issuedAt = $record->created_at->toImmutable();

    expect(config('sanctum.expiration'))->toBeNull()
        ->and($record->expires_at->equalTo($issuedAt->addDays(30)))->toBeTrue()
        ->and($digest)->toBe(hash('sha256', explode('|', $token, 2)[1]));

    $this->travel(1)->days();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();
    expect($record->fresh()->expires_at->equalTo($issuedAt->addDays(30)))->toBeTrue();

    foreach ([14, 15, 15, 15, 15] as $days) {
        $this->travel($days)->days();
        sessionRequest($token, 'users.get', ['user' => $userId])->assertOk()->assertDontSee($token);
    }

    expect($record->fresh()->expires_at->equalTo($issuedAt->addDays(90)))->toBeTrue()
        ->and($record->fresh()->created_at->equalTo($issuedAt))->toBeTrue()
        ->and($record->fresh()->token)->toBe($digest)
        ->and($record->fresh()->getKey())->toBe($id)
        ->and($user->tokens()->count())->toBe(1);

    $this->travel(15)->days();
    sessionRequest($token, 'users.get', ['user' => $userId])
        ->assertUnauthorized()->assertHeader('Content-Type', 'application/vnd.api+json');
    expect($record->fresh()->expires_at->equalTo($issuedAt->addDays(90)))->toBeTrue();
});

it('treats sign-in expiry as an initial snapshot and declines renewal after inactivity', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now())->getKey();
    $response = $this->postJson(route('authentication.api.sign-in'), [
        'data' => ['type' => 'access-tokens', 'attributes' => ['email' => 'maria@example.com', 'password' => 'Correct1']],
    ])->assertOk()->assertHeader('Pragma', 'no-cache');
    expect($response->headers->get('Cache-Control'))->toContain('no-store');
    $token = $response->json('data.attributes.token');
    $record = UserModel::query()->findOrFail($userId)->tokens()->sole();

    expect($response->json('data.attributes.expires_at'))->toBe($record->expires_at->format(DATE_ATOM))
        ->and($response->json('data.attributes.token_type'))->toBe('Bearer');

    $this->travel(1)->days();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();
    $this->travel(29)->days();
    sessionRequest($token, 'expenses.index')->assertUnauthorized();
    expect($record->fresh()->expires_at->equalTo($record->created_at->toImmutable()->addDays(30)))->toBeTrue();
});

it('renews at the inclusive 15-day boundary, never early, and caps extension at 90 days', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now())->getKey();
    $token = (new IdentityHttpJourney($this))->signIn();
    $record = UserModel::query()->findOrFail($userId)->tokens()->sole();
    $issuedAt = $record->created_at->toImmutable();

    $this->travel(14)->days();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();
    expect($record->fresh()->expires_at->equalTo($issuedAt->addDays(30)))->toBeTrue();

    $this->travel(1)->days();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();
    expect($record->fresh()->expires_at->equalTo($issuedAt->addDays(45)))->toBeTrue();

    foreach ([15, 15, 15, 15] as $days) {
        $this->travel($days)->days();
        sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();
    }

    expect($record->fresh()->expires_at->equalTo($issuedAt->addDays(90)))->toBeTrue();
    $this->travel(1)->days();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();
    expect($record->fresh()->expires_at->equalTo($issuedAt->addDays(90)))->toBeTrue();
});

it('keeps a weekly visitor authenticated until the absolute limit', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now())->getKey();
    $token = (new IdentityHttpJourney($this))->signIn();
    $record = PersonalAccessToken::findToken($token);

    for ($week = 1; $week <= 12; $week++) {
        $this->travel(7)->days();
        sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();
    }

    expect($record->fresh()->expires_at->equalTo($record->created_at->toImmutable()->addDays(90)))->toBeTrue();
    $this->travel(6)->days();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertUnauthorized();
});

it('does not renew rejected requests, blocked accounts, or sign-out and leaves other logins alone', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now())->getKey();
    $journey = new IdentityHttpJourney($this);
    $first = $journey->signIn();
    $second = $journey->signIn();
    $user = UserModel::query()->findOrFail($userId);
    $record = PersonalAccessToken::findToken($first);
    $original = $record->expires_at;

    foreach ([$first, $second] as $index => $bearer) {
        $registration = UuidSchemaFixture::row('notifications');
        $registration['id'] = UuidFixture::at(500 + $index);
        $registration['user_id'] = $userId;
        $registration['session_id'] = PersonalAccessToken::findToken($bearer)->id;
        $registration['installation_id'] = UuidFixture::at(600 + $index);
        $registration['identifier_fingerprint'] = str_repeat($index === 0 ? 'a' : 'b', 64);
        DB::table('notifications')->insert($registration);
    }

    $this->travel(16)->days();
    sessionRequest('invalid-token', 'expenses.index')->assertUnauthorized();
    Auth::forgetGuards();
    $this->getJson(route('expenses.index'))->assertUnauthorized();
    sessionRequest($first, 'users.get', ['user' => UuidFixture::at(999)])->assertNotFound();
    sessionRequest($first, 'users.get', ['user' => $userId])->assertOk();
    expect($record->fresh()->expires_at->greaterThan($original))->toBeTrue()
        ->and(PersonalAccessToken::findToken($second)->expires_at->equalTo($original))->toBeTrue();

    $user->update(['status' => UserStatusEnum::Blocked]);
    sessionRequest($second, 'expenses.index')->assertForbidden();
    expect(PersonalAccessToken::findToken($second)->expires_at->equalTo($original))->toBeTrue();

    $user->update(['status' => UserStatusEnum::Active]);
    Auth::forgetGuards();
    withToken($second)->deleteJson(route('authentication.api.sign-out'))->assertNoContent();
    expect(PersonalAccessToken::findToken($second))->toBeNull()
        ->and($record->fresh())->not->toBeNull()
        ->and(DB::table('notifications')->pluck('session_id')->all())->toBe([$record->id]);
    sessionRequest($second, 'expenses.index')->assertUnauthorized();
});

it('rechecks persistence before extending and prunes legacy tokens by individual expiry', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now())->getKey();
    $token = (new IdentityHttpJourney($this))->signIn();
    $record = PersonalAccessToken::findToken($token);
    $registration = UuidSchemaFixture::row('notifications');
    $registration['user_id'] = $userId;
    $registration['session_id'] = $record->id;
    DB::table('notifications')->insert($registration);
    $record->forceFill(['expires_at' => now()->addHours(2)])->save();

    $this->travel(1)->hours();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();
    expect($record->fresh()->expires_at->greaterThan(now()->addDays(29)))->toBeTrue();

    $record->forceFill(['expires_at' => now()->addMinute()])->save();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();
    $record->forceFill(['expires_at' => now()->subSecond()])->save();
    app(SessionAdapter::class)->extendCurrentToken();
    expect($record->fresh()->expires_at->isPast())->toBeTrue();
    sessionRequest($token, 'expenses.index')->assertUnauthorized();

    $record->forceFill(['expires_at' => now()->subHours(25)])->save();
    Artisan::call('sanctum:prune-expired', ['--hours' => 24]);
    expect($record->fresh())->toBeNull()->and(DB::table('notifications')->count())->toBe(0);
});

it('does not extend for validation, rate limit, server error, or unverified email', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now())->getKey();
    $token = (new IdentityHttpJourney($this))->signIn();
    $record = PersonalAccessToken::findToken($token);
    $expiresAt = $record->expires_at;
    $this->travel(16)->days();

    Auth::forgetGuards();
    withToken($token)->patchJson(route('users.update', ['user' => $userId]), [
        'data' => ['type' => 'users', 'id' => (string) $userId, 'attributes' => ['name' => '1']],
    ])->assertUnprocessable();
    expect($record->fresh()->expires_at->equalTo($expiresAt))->toBeTrue();

    $rateLimitKey = md5('api.authenticatedapi:authenticated:user:'.$userId);
    for ($attempt = 0; $attempt < 60; $attempt++) {
        RateLimiter::hit($rateLimitKey, 60);
    }
    sessionRequest($token, 'expenses.index')->assertTooManyRequests();
    expect($record->fresh()->expires_at->equalTo($expiresAt))->toBeTrue();
    RateLimiter::clear($rateLimitKey);

    Route::get('/api/session-failure', fn (): never => throw new RuntimeException('Falha de teste'))
        ->middleware(['auth:sanctum', 'user.active', 'verified', 'session.extend']);
    Auth::forgetGuards();
    withToken($token)->getJson('/api/session-failure')->assertInternalServerError();
    expect($record->fresh()->expires_at->equalTo($expiresAt))->toBeTrue();

    UserModel::query()->whereKey($userId)->update(['email_verified_at' => null]);
    sessionRequest($token, 'users.get', ['user' => $userId])->assertForbidden();
    expect($record->fresh()->expires_at->equalTo($expiresAt))->toBeTrue();
});

it('does not recreate a revoked token or revive a token expired after authentication', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now())->getKey();
    $token = (new IdentityHttpJourney($this))->signIn();
    $record = PersonalAccessToken::findToken($token);
    $this->travel(16)->days();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();

    $record->forceFill(['expires_at' => now()->subSecond()])->save();
    app(SessionAdapter::class)->extendCurrentToken();
    expect($record->fresh()->expires_at->isPast())->toBeTrue();

    $record->delete();
    app(SessionAdapter::class)->extendCurrentToken();
    expect(PersonalAccessToken::findToken($token))->toBeNull();
});

it('rejects a token at 90 days even when its stored expiry is later or absent', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now())->getKey();
    $token = (new IdentityHttpJourney($this))->signIn();
    $record = PersonalAccessToken::findToken($token);
    $issuedAt = $record->created_at->toImmutable();

    $record->forceFill(['expires_at' => $issuedAt->addDays(365)])->save();
    $this->travel(89)->days();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();

    $record->forceFill(['expires_at' => null])->save();
    sessionRequest($token, 'expenses.index')->assertUnauthorized();
    $record->forceFill(['expires_at' => $issuedAt->addDays(365)])->save();

    $this->travel(1)->days();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertUnauthorized();
    Auth::forgetGuards();
    withToken($token)->deleteJson(route('authentication.api.sign-out'))->assertUnauthorized();
    expect($record->fresh()->expires_at->equalTo($issuedAt->addDays(365)))->toBeTrue();
});

it('uses the fixed session policy when the adapter is called directly', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now())->getKey();
    $token = (new IdentityHttpJourney($this))->signIn();
    $record = PersonalAccessToken::findToken($token);
    $issuedAt = $record->created_at->toImmutable();

    $this->travel(16)->days();
    sessionRequest($token, 'users.get', ['user' => UuidFixture::at(999)])->assertNotFound();
    app(SessionAdapter::class)->extendCurrentToken();

    expect($record->fresh()->expires_at->equalTo($issuedAt->addDays(46)))->toBeTrue()
        ->and($record->fresh()->created_at->equalTo($issuedAt))->toBeTrue();

    $this->travel(74)->days();
    sessionRequest($token, 'expenses.index')->assertUnauthorized();
});

it('finishes a nonrenewing fresh read while the same or another PAT is locked', function (bool $samePat): void {
    $reference = CarbonImmutable::parse('2026-01-01 12:00:00');
    $this->travelTo($reference);
    $user = IdentityFixture::create(UserStatusEnum::Active, $reference);
    $first = IdentityFixture::token($user, $reference->addDays(30), 'first');
    $second = IdentityFixture::token($user, $reference->addDays(30), 'second');
    $lockedId = PersonalAccessToken::findToken($first)->id;
    $this->travel(1)->days();
    sessionRequest($samePat ? $first : $second, 'users.get', ['user' => UuidFixture::at(999)])->assertNotFound();

    $child = new ConcurrentDatabaseProcess(static function (): void {
        $connection = DB::connection();
        $connection->statement('SET statement_timeout = 2000');
        $connection->enableQueryLog();
        $connection->flushQueryLog();
        app(SessionAdapter::class)->extendCurrentToken();
        $queries = $connection->getQueryLog();
        expect($queries)->toHaveCount(1)
            ->and($queries[0]['query'])->not->toContain('for update')
            ->and($connection->transactionLevel())->toBe(0);
    });

    try {
        DB::transaction(function () use ($child, $lockedId, $samePat): void {
            PersonalAccessToken::query()->whereKey($lockedId)->lockForUpdate()->firstOrFail();
            $start = hrtime(true);
            $child->go();
            $child->done();
            fwrite(STDOUT, "\nSession adapter completion ".json_encode([
                'same_pat' => $samePat,
                'ms_including_ipc' => round((hrtime(true) - $start) / 1_000_000, 3),
                'completed_while_lock_held' => true,
            ], JSON_THROW_ON_ERROR)."\n");
        });
    } finally {
        $child->close();
    }
})->with(['same PAT' => true, 'distinct session' => false])->group('concurrency', 'integration');

it('separates same-PAT HTTP tracking contention from nonrenewing session work', function (bool $samePat): void {
    $reference = CarbonImmutable::parse('2026-01-01 12:00:00');
    $this->travelTo($reference);
    $user = IdentityFixture::create(UserStatusEnum::Active, $reference);
    $first = IdentityFixture::token($user, $reference->addDays(30), 'first');
    $second = IdentityFixture::token($user, $reference->addDays(30), 'second');
    $lockedId = PersonalAccessToken::findToken($first)->id;
    $bearer = $samePat ? $first : $second;
    $userId = $user->id;
    $this->travel(1)->days();
    expect(config('sanctum.last_used_at'))->toBeTrue();

    $child = new ConcurrentDatabaseProcess(static function () use ($bearer, $userId): void {
        $connection = DB::connection();
        $connection->statement('SET statement_timeout = 4000');
        $connection->enableQueryLog();
        $connection->flushQueryLog();
        sessionRequest($bearer, 'users.get', ['user' => $userId])->assertOk();
        $queries = $connection->getQueryLog();
        $writes = array_filter($queries, static fn (array $query): bool => str_starts_with($query['query'], 'update "personal_access_tokens"')
            && str_contains($query['query'], '"last_used_at"'));
        expect($writes)->toHaveCount(1)
            ->and(array_filter($queries, static fn (array $query): bool => str_contains($query['query'], 'for update')))->toBe([]);
    });

    try {
        $start = hrtime(true);
        DB::transaction(function () use ($child, $lockedId, $samePat): void {
            PersonalAccessToken::query()->whereKey($lockedId)->lockForUpdate()->firstOrFail();
            $child->go();
            if ($samePat) {
                $child->awaitLock();
            } else {
                $child->done();
            }
        });
        if ($samePat) {
            $child->done();
        }
        fwrite(STDOUT, "\nSession HTTP completion ".json_encode([
            'same_pat' => $samePat,
            'ms_including_ipc_and_lock_release' => round((hrtime(true) - $start) / 1_000_000, 3),
            'tracking_lock_observed' => $samePat,
            'status' => 200,
        ], JSON_THROW_ON_ERROR)."\n");
    } finally {
        $child->close();
    }
})->with(['same PAT' => true, 'distinct session' => false])->group('concurrency', 'integration');

it('observes committed changes on the next invocation after a nonrenewing snapshot', function (string $change): void {
    $reference = CarbonImmutable::parse('2026-01-01 12:00:00');
    $this->travelTo($reference);
    $user = IdentityFixture::create(UserStatusEnum::Active, $reference);
    $token = IdentityFixture::token($user, $reference->addDays(30));
    $id = PersonalAccessToken::findToken($token)->id;
    $this->travel(1)->days();
    sessionRequest($token, 'users.get', ['user' => UuidFixture::at(999)])->assertNotFound();

    $child = new ConcurrentDatabaseProcess(static function (): void {
        DB::statement('SET statement_timeout = 2000');
        app(SessionAdapter::class)->extendCurrentToken();
        expect(DB::connection()->transactionLevel())->toBe(0);
    });

    try {
        DB::transaction(function () use ($child, $id, $change, $reference): void {
            $locked = PersonalAccessToken::query()->whereKey($id)->lockForUpdate()->firstOrFail();
            match ($change) {
                'shorten' => $locked->forceFill(['expires_at' => now()->addDays(2)])->save(),
                'extend' => $locked->forceFill(['expires_at' => $reference->addDays(60)])->save(),
                'expire' => $locked->forceFill(['expires_at' => now()->subSecond()])->save(),
                'revoke' => $locked->delete(),
            };
            $child->go();
            $child->done();
        });
    } finally {
        $child->close();
    }

    app(SessionAdapter::class)->extendCurrentToken();
    $persisted = PersonalAccessToken::query()->find($id);
    if ($change === 'revoke') {
        expect($persisted)->toBeNull();
    } else {
        $expected = match ($change) {
            'shorten' => now()->addDays(30),
            'extend' => $reference->addDays(60),
            'expire' => now()->subSecond(),
        };
        expect($persisted->expires_at->equalTo($expected))->toBeTrue();
    }
    if (in_array($change, ['expire', 'revoke'], true)) {
        sessionRequest($token, 'users.get', ['user' => $user->id])->assertUnauthorized();
    }
})->with(['shorten', 'extend', 'expire', 'revoke'])->group('concurrency', 'integration');

it('revalidates the locked token against a concurrent extension, revocation expiry or shortening', function (string $change): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now())->getKey();
    $token = (new IdentityHttpJourney($this))->signIn();
    $record = PersonalAccessToken::findToken($token);
    $id = $record->getKey();
    $digest = $record->token;
    $issuedAt = $record->created_at->toImmutable();
    $this->travel(16)->days();

    sessionRequest($token, 'users.get', ['user' => UuidFixture::at(999)])->assertNotFound();

    $child = new ConcurrentDatabaseProcess(static function (): void {
        app(SessionAdapter::class)->extendCurrentToken();
    });

    try {
        DB::transaction(function () use ($child, $id, $change, $issuedAt): void {
            $locked = PersonalAccessToken::query()->whereKey($id)->lockForUpdate()->firstOrFail();
            $child->go();
            $child->awaitLock();

            match ($change) {
                'extend' => $locked->forceFill(['expires_at' => $issuedAt->addDays(60)])->save(),
                'revoke' => $locked->delete(),
                'expire' => $locked->forceFill(['expires_at' => now()->subSecond()])->save(),
                'shorten' => $locked->forceFill(['expires_at' => $issuedAt->addDays(20)])->save(),
            };
        });

        $child->done();
    } finally {
        $child->close();
    }

    $persisted = $record->fresh();

    if ($change === 'revoke') {
        expect($persisted)->toBeNull()
            ->and(PersonalAccessToken::findToken($token))->toBeNull();

        return;
    }

    $expectedExpiry = match ($change) {
        'extend' => $issuedAt->addDays(60),
        'expire' => now()->subSecond(),
        'shorten' => $issuedAt->addDays(46),
    };

    expect($persisted->token)->toBe($digest)
        ->and($persisted->created_at->equalTo($issuedAt))->toBeTrue()
        ->and($persisted->getKey())->toBe($id)
        ->and($persisted->expires_at->equalTo($expectedExpiry))->toBeTrue()
        ->and(UserModel::query()->findOrFail($userId)->tokens()->count())->toBe(1);
})->with(['extend', 'revoke', 'expire', 'shorten'])->group('concurrency', 'integration');
