<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Adapters\SessionExtensionAdapter;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\PersonalAccessToken;

use function Pest\Laravel\withToken;

function sessionRequest(string $token, string $route, array $parameters = []): TestResponse
{
    Auth::forgetGuards();

    return withToken($token)->getJson(route($route, $parameters));
}

it('issues a single expiring Sanctum token and keeps its bearer and hash on fortnightly activity', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
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
        sessionRequest($token, 'expenses.index')->assertOk()->assertDontSee($token);
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
    $userId = signUpIdentityByApi($this);
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
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $record = UserModel::query()->findOrFail($userId)->tokens()->sole();
    $issuedAt = $record->created_at->toImmutable();

    $this->travel(14)->days();
    sessionRequest($token, 'expenses.index')->assertOk();
    expect($record->fresh()->expires_at->equalTo($issuedAt->addDays(30)))->toBeTrue();

    $this->travel(1)->days();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();
    expect($record->fresh()->expires_at->equalTo($issuedAt->addDays(45)))->toBeTrue();

    foreach ([15, 15, 15, 15] as $days) {
        $this->travel($days)->days();
        sessionRequest($token, 'expenses.index')->assertOk();
    }

    expect($record->fresh()->expires_at->equalTo($issuedAt->addDays(90)))->toBeTrue();
    $this->travel(1)->days();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();
    expect($record->fresh()->expires_at->equalTo($issuedAt->addDays(90)))->toBeTrue();
});

it('keeps a weekly visitor authenticated until the absolute limit', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
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
    $userId = signUpIdentityByApi($this);
    $first = signInIdentityByApi($this);
    $second = signInIdentityByApi($this);
    $user = UserModel::query()->findOrFail($userId);
    $record = PersonalAccessToken::findToken($first);
    $original = $record->expires_at;

    $this->travel(16)->days();
    sessionRequest('invalid-token', 'expenses.index')->assertUnauthorized();
    Auth::forgetGuards();
    $this->getJson(route('expenses.index'))->assertUnauthorized();
    sessionRequest($first, 'users.get', ['user' => $userId + 1])->assertNotFound();
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
        ->and($record->fresh())->not->toBeNull();
    sessionRequest($second, 'expenses.index')->assertUnauthorized();
});

it('rechecks persistence before extending and prunes legacy tokens by individual expiry', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $record = PersonalAccessToken::findToken($token);
    $record->forceFill(['expires_at' => now()->addHours(2)])->save();

    $this->travel(1)->hours();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();
    expect($record->fresh()->expires_at->greaterThan(now()->addDays(29)))->toBeTrue();

    $record->forceFill(['expires_at' => now()->addMinute()])->save();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();
    $record->forceFill(['expires_at' => now()->subSecond()])->save();
    app(SessionExtensionAdapter::class)->extendCurrentToken(15, 30, 90);
    expect($record->fresh()->expires_at->isPast())->toBeTrue();
    sessionRequest($token, 'expenses.index')->assertUnauthorized();

    $record->forceFill(['expires_at' => now()->subHours(25)])->save();
    Artisan::call('sanctum:prune-expired', ['--hours' => 24]);
    expect($record->fresh())->toBeNull();
});

it('does not extend for validation, rate limit, server error, or unverified email', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
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
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $record = PersonalAccessToken::findToken($token);
    $this->travel(16)->days();
    sessionRequest($token, 'users.get', ['user' => $userId])->assertOk();

    $record->forceFill(['expires_at' => now()->subSecond()])->save();
    app(SessionExtensionAdapter::class)->extendCurrentToken(15, 30, 90);
    expect($record->fresh()->expires_at->isPast())->toBeTrue();

    $record->delete();
    app(SessionExtensionAdapter::class)->extendCurrentToken(15, 30, 90);
    expect(PersonalAccessToken::findToken($token))->toBeNull();
});

it('rejects a token at 90 days even when its stored expiry is later or absent', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
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

it('never writes an expiry beyond 90 days even if the adapter receives a larger age', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $record = PersonalAccessToken::findToken($token);
    $issuedAt = $record->created_at->toImmutable();

    $this->travel(16)->days();
    sessionRequest($token, 'users.get', ['user' => $userId + 1])->assertNotFound();
    app(SessionExtensionAdapter::class)->extendCurrentToken(365, 365, 365);

    expect($record->fresh()->expires_at->equalTo($issuedAt->addDays(90)))->toBeTrue()
        ->and($record->fresh()->created_at->equalTo($issuedAt))->toBeTrue();

    $this->travel(74)->days();
    sessionRequest($token, 'expenses.index')->assertUnauthorized();
});

it('revalidates the locked token against a concurrent extension, revocation or expiry', function (string $change): void {
    if (! function_exists('pcntl_fork')) {
        $this->markTestSkipped('A execução concorrente requer pcntl.');
    }

    $this->travelTo(CarbonImmutable::parse('2026-01-01 12:00:00'));
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $record = PersonalAccessToken::findToken($token);
    $id = $record->getKey();
    $digest = $record->token;
    $issuedAt = $record->created_at->toImmutable();
    $this->travel(16)->days();

    sessionRequest($token, 'users.get', ['user' => $userId + 1])->assertNotFound();

    $sockets = stream_socket_pair(STREAM_PF_UNIX, STREAM_SOCK_STREAM, STREAM_IPPROTO_IP);
    expect($sockets)->toBeArray();
    $pid = pcntl_fork();
    expect($pid)->not->toBe(-1);

    if ($pid === 0) {
        fclose($sockets[0]);

        try {
            DB::disconnect();
            $backend = DB::selectOne('SELECT pg_backend_pid() AS pid');
            fwrite($sockets[1], "ready:{$backend->pid}\n");

            if (trim((string) fgets($sockets[1])) !== 'go') {
                throw new RuntimeException('O processo concorrente não recebeu o sinal de início.');
            }

            app(SessionExtensionAdapter::class)->extendCurrentToken(15, 30, 90);
            fwrite($sockets[1], "done\n");
        } catch (Throwable $exception) {
            fwrite($sockets[1], 'error: '.$exception->getMessage()."\n");
        }

        fclose($sockets[1]);
        exit;
    }

    fclose($sockets[1]);
    stream_set_timeout($sockets[0], 5);

    try {
        $ready = trim((string) fgets($sockets[0]));
        expect($ready)->toStartWith('ready:');
        $backendPid = (int) substr($ready, 6);

        DB::transaction(function () use ($sockets, $id, $change, $issuedAt, $backendPid): void {
            $locked = PersonalAccessToken::query()->whereKey($id)->lockForUpdate()->firstOrFail();
            fwrite($sockets[0], "go\n");

            $blocked = false;

            for ($attempt = 0; $attempt < 100; $attempt++) {
                if (DB::selectOne('SELECT wait_event_type FROM pg_stat_activity WHERE pid = ?', [$backendPid])?->wait_event_type === 'Lock') {
                    $blocked = true;

                    break;
                }

                usleep(10000);
            }

            expect($blocked)->toBeTrue();

            match ($change) {
                'extend' => $locked->forceFill(['expires_at' => $issuedAt->addDays(60)])->save(),
                'revoke' => $locked->delete(),
                'expire' => $locked->forceFill(['expires_at' => now()->subSecond()])->save(),
            };
        });

        expect(trim((string) fgets($sockets[0])))->toBe('done');
    } finally {
        fclose($sockets[0]);
        pcntl_waitpid($pid, $status);
    }

    $persisted = $record->fresh();

    if ($change === 'revoke') {
        expect($persisted)->toBeNull()
            ->and(PersonalAccessToken::findToken($token))->toBeNull();

        return;
    }

    expect($persisted->token)->toBe($digest)
        ->and($persisted->created_at->equalTo($issuedAt))->toBeTrue()
        ->and($persisted->getKey())->toBe($id)
        ->and($persisted->expires_at->equalTo($change === 'extend' ? $issuedAt->addDays(60) : now()->subSecond()))->toBeTrue()
        ->and(UserModel::query()->findOrFail($userId)->tokens()->count())->toBe(1);
})->with(['extend', 'revoke', 'expire']);
