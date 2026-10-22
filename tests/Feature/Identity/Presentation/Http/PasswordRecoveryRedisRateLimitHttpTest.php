<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Passwords\PasswordBrokerManager;
use Illuminate\Cache\RateLimiter;
use Illuminate\Cache\RedisStore;
use Illuminate\Notifications\SendQueuedNotifications;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\RateLimiter as RateLimiterFacade;
use Tests\Support\Core\Fixtures\ConcurrentDatabaseProcess;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:00 UTC'));
    config(['mail.default' => 'array', 'identity.password_recovery.url' => 'https://app.example.com/reset']);
    Queue::fake();
    $registered = app(RateLimiter::class);
    config(['cache.limiter' => 'redis']);
    $this->unavailableSocket = stream_socket_server('tcp://127.0.0.1:0', $errorCode, $errorMessage, STREAM_SERVER_BIND);
    expect($this->unavailableSocket)->not->toBeFalse();
    $address = stream_socket_get_name($this->unavailableSocket, false);
    config(['database.redis.recovery_limiter_unavailable' => [
        'host' => '127.0.0.1', 'port' => (int) substr($address, strrpos($address, ':') + 1), 'database' => 0,
        'timeout' => 0.2, 'read_timeout' => 0.2, 'retry_interval' => 0, 'max_retries' => 0,
    ]]);
    app()->forgetInstance(RateLimiter::class);
    RateLimiterFacade::clearResolvedInstance(RateLimiter::class);
    Cache::forgetDriver('redis');
    $this->limiter = app(RateLimiter::class);
    foreach (['authentication.forgot-password', 'authentication.reset-password', 'authentication.sign-in', 'authentication.sign-up', 'authentication.email-verification'] as $name) {
        $this->limiter->for($name, $registered->limiter($name));
    }
    $this->store = Cache::store('redis')->getStore();
    expect($this->store)->toBeInstanceOf(RedisStore::class);
    $this->user = IdentityFixture::create(UserStatusEnum::Active, now());
    IdentityFixture::token($this->user, now()->addDays(30));
    $this->native = app(PasswordBrokerManager::class)->broker('users')->getRepository();
    $this->token = $this->native->create($this->user);
    $this->forgot = ['data' => ['type' => 'password-recovery-requests', 'attributes' => ['email' => 'maria@example.com']]];
    $this->reset = ['data' => ['type' => 'password-resets', 'attributes' => [
        'email' => 'maria@example.com', 'token' => $this->token,
        'password' => 'Newpass1', 'password_confirmation' => 'Newpass1',
    ]]];
});

afterEach(function (): void {
    if (isset($this->unavailableSocket) && is_resource($this->unavailableSocket)) {
        fclose($this->unavailableSocket);
    }
});

it('combines real HTTP attempts across independent process clients and counts success and invalid requests', function (string $endpoint): void {
    $url = route('authentication.api.'.$endpoint);
    $payload = $endpoint === 'forgot-password' ? $this->forgot : $this->reset;
    $key = md5('authentication.'.$endpoint.$endpoint.':ip:127.0.0.1');
    $other = IdentityFixture::create(UserStatusEnum::Active, now(), email: 'other@example.com');
    IdentityFixture::token($other, now()->addDays(30));
    if ($endpoint === 'forgot-password') {
        $this->native->delete($this->user);
    }

    $this->postJson($url, $payload)->assertStatus($endpoint === 'forgot-password' ? 202 : 204);
    $this->postJson($url, [])->assertUnprocessable();
    $this->postJson($url, $payload)->assertStatus($endpoint === 'forgot-password' ? 202 : 422);
    expect((int) $this->limiter->attempts($key))->toBe(3);
    $before = [DB::table('users')->orderBy('id')->get()->all(), DB::table('personal_access_tokens')->orderBy('id')->get()->all(), DB::table('password_reset_tokens')->get()->all()];
    $jobs = Queue::pushedJobs();
    $child = new ConcurrentDatabaseProcess(function () use ($url, $key, $payload): void {
        DB::statement('SET statement_timeout = 4000');
        expect((int) app(RateLimiter::class)->attempts($key))->toBe(3);
        for ($attempt = 0; $attempt < 3; $attempt++) {
            $this->postJson($url, [])->assertUnprocessable();
        }
        expect((int) app(RateLimiter::class)->attempts($key))->toBe(6);
        $this->postJson($url, $payload)->assertTooManyRequests()->assertHeader('Retry-After', '600');
    });
    try {
        $child->go();
        $child->done();
        $this->postJson($url, $payload)->assertTooManyRequests()
            ->assertHeader('Content-Type', 'application/vnd.api+json')->assertHeader('Retry-After', '600')
            ->assertExactJson(['errors' => [[
                'title' => 'Muitas solicitações', 'detail' => 'O limite de solicitações foi excedido. Tente novamente mais tarde.', 'status' => '429',
            ]]]);
        expect((int) $this->limiter->attempts($key))->toBe(6)
            ->and([DB::table('users')->orderBy('id')->get()->all(), DB::table('personal_access_tokens')->orderBy('id')->get()->all(), DB::table('password_reset_tokens')->get()->all()])->toEqual($before)
            ->and(Queue::pushedJobs())->toEqual($jobs);
        $connection = $this->store->connection();
        foreach ([$key, $key.':timer'] as $member) {
            expect((int) $connection->ttl($this->store->getPrefix().$member))->toBeGreaterThan(590)->toBeLessThanOrEqual(600);
        }
        $cursor = null;
        $keys = [];
        do {
            $batch = $connection->client()->scan($cursor, $this->resources->namespace.'*', 100);
            if ($batch !== false) {
                array_push($keys, ...$batch);
            }
        } while ($cursor !== 0);
        expect($keys)->not->toBeEmpty();
        foreach ($keys as $storedKey) {
            expect($storedKey)->toStartWith($this->resources->namespace)
                ->not->toContain('maria@example.com', $this->token, 'Newpass1');
        }
    } finally {
        $child->close();
    }
})->with(['forgot-password', 'reset-password'])->group('integration', 'redis', 'concurrency');

it('keeps endpoint IP and existing authentication quotas independent in Redis', function (string $endpoint): void {
    $url = route('authentication.api.'.$endpoint);
    for ($attempt = 0; $attempt < 6; $attempt++) {
        $this->postJson($url, [])->assertUnprocessable();
    }
    $this->postJson($url, [])->assertTooManyRequests();
    $otherEndpoint = $endpoint === 'forgot-password' ? 'reset-password' : 'forgot-password';
    for ($attempt = 0; $attempt < 6; $attempt++) {
        $this->postJson(route('authentication.api.'.$otherEndpoint), [])->assertUnprocessable();
    }
    $this->postJson(route('authentication.api.'.$otherEndpoint), [])->assertTooManyRequests();
    $this->postJson(route('authentication.api.sign-in'), [])->assertUnprocessable();
    $this->postJson(route('authentication.api.sign-up'), [])->assertUnprocessable();
    $this->postJson(route('authentication.api.email-verification.resend'), [])->assertUnprocessable();
    foreach ([$endpoint, $otherEndpoint] as $name) {
        $this->withServerVariables(['REMOTE_ADDR' => '192.0.2.20'])->postJson(route('authentication.api.'.$name), [])->assertUnprocessable();
    }
    expect($this->native->exists($this->user, $this->token))->toBeTrue()
        ->and($this->user->tokens()->count())->toBe(1)->and(Hash::check('Correct1', $this->user->fresh()->password))->toBeTrue();
    Queue::assertNothingPushed();
})->with(['forgot-password', 'reset-password'])->group('integration', 'redis');

it('does not spend recovery quotas when other authentication quotas are exhausted in Redis', function (): void {
    foreach (['sign-in' => 5, 'sign-up' => config('identity.sign_up.per_hour'), 'email-verification.resend' => 2] as $name => $quota) {
        for ($attempt = 0; $attempt < $quota; $attempt++) {
            $this->postJson(route('authentication.api.'.$name), [])->assertUnprocessable();
        }
        $this->postJson(route('authentication.api.'.$name), [])->assertTooManyRequests();
    }
    foreach (['forgot-password', 'reset-password'] as $endpoint) {
        for ($attempt = 0; $attempt < 6; $attempt++) {
            $this->postJson(route('authentication.api.'.$endpoint), [])->assertUnprocessable();
        }
        $this->postJson(route('authentication.api.'.$endpoint), [])->assertTooManyRequests();
    }
    expect($this->native->exists($this->user, $this->token))->toBeTrue()
        ->and(Hash::check('Correct1', $this->user->fresh()->password))->toBeTrue()->and($this->user->tokens()->count())->toBe(1);
    Queue::assertNothingPushed();
})->group('integration', 'redis');

it('reopens after Redis expiration without changing the configured ten minute policy', function (string $endpoint): void {
    $url = route('authentication.api.'.$endpoint);
    $key = md5('authentication.'.$endpoint.$endpoint.':ip:127.0.0.1');
    for ($attempt = 0; $attempt < 6; $attempt++) {
        $this->postJson($url, [])->assertUnprocessable();
    }
    $this->postJson($url, [])->assertTooManyRequests()->assertHeader('Retry-After', '600');
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:09:59 UTC'));
    $this->postJson($url, [])->assertTooManyRequests()->assertHeader('Retry-After', '1');
    $connection = $this->store->connection();
    foreach ([$key, $key.':timer'] as $member) {
        $cacheKey = $this->store->getPrefix().$member;
        expect((int) $connection->ttl($cacheKey))->toBeGreaterThan(590)->toBeLessThanOrEqual(600);
        $connection->pexpireat($cacheKey, 1);
        expect((int) $connection->exists($cacheKey))->toBe(0);
    }
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:10:00 UTC'));
    $this->postJson($url, [])->assertUnprocessable();
    expect((int) $this->limiter->attempts($key))->toBe(1);
    Queue::assertNothingPushed();
})->with(['forgot-password', 'reset-password'])->group('integration', 'redis');

it('keeps the global canonical email interval across process clients and IPs with real Redis quotas', function (): void {
    $this->native->delete($this->user);
    $url = route('authentication.api.forgot-password');
    $this->postJson($url, $this->forgot)->assertAccepted();
    $first = (array) DB::table('password_reset_tokens')->sole();
    $firstJob = Queue::pushed(SendQueuedNotifications::class)->sole();
    parse_str(parse_url($firstJob->notification->toMail($this->user)->actionUrl, PHP_URL_QUERY), $firstQuery);
    $beforeUser = $this->user->fresh()->getRawOriginal();
    $payload = $this->forgot;
    $payload['data']['attributes']['email'] = ' MARIA@EXAMPLE.COM ';
    $child = new ConcurrentDatabaseProcess(function () use ($url, $payload, $first, $firstQuery): void {
        DB::statement('SET statement_timeout = 4000');
        $jobsBefore = Queue::pushedJobs();
        $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:59 UTC'));
        $this->withServerVariables(['REMOTE_ADDR' => '192.0.2.21'])->postJson($url, $payload)
            ->assertAccepted()->assertExactJson(['meta' => ['message' => 'Se a conta estiver apta, enviaremos as instruções de recuperação.']]);
        expect((array) DB::table('password_reset_tokens')->sole())->toBe($first)->and(Queue::pushedJobs())->toEqual($jobsBefore);
        $this->travelTo(CarbonImmutable::parse('2026-10-21 12:01:00 UTC'));
        $this->withServerVariables(['REMOTE_ADDR' => '192.0.2.22'])->postJson($url, $payload)->assertAccepted();
        $current = DB::table('password_reset_tokens')->sole();
        expect($current->created_at)->toBe('2026-10-21 12:01:00')->and($current->token)->not->toBe($first['token']);
        expect($this->native->exists($this->user, $firstQuery['token']))->toBeFalse();
        $newJob = Queue::pushed(SendQueuedNotifications::class)->last();
        parse_str(parse_url($newJob->notification->toMail($this->user)->actionUrl, PHP_URL_QUERY), $newQuery);
        expect(Hash::check($newQuery['token'], $current->token))->toBeTrue()
            ->and(Queue::pushed(SendQueuedNotifications::class))->toHaveCount(2);
    });
    try {
        $child->go();
        $child->done();
        $current = DB::table('password_reset_tokens')->sole();
        expect($current->created_at)->toBe('2026-10-21 12:01:00')->and($current->token)->not->toBe($first['token'])
            ->and($this->user->fresh()->getRawOriginal())->toBe($beforeUser)->and($this->user->tokens()->count())->toBe(1);
        foreach (['127.0.0.1', '192.0.2.21', '192.0.2.22'] as $ip) {
            expect((int) $this->limiter->attempts(md5('authentication.forgot-passwordforgot-password:ip:'.$ip)))->toBe(1);
        }
    } finally {
        $child->close();
    }
})->group('integration', 'redis', 'concurrency');

it('fails closed on an actual unavailable Redis connection without local counting or recovery effects', function (string $endpoint): void {
    $original = config('cache.stores.redis.connection');
    $key = md5('authentication.'.$endpoint.$endpoint.':ip:127.0.0.1');
    $before = [DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()];
    try {
        $this->store->setConnection('recovery_limiter_unavailable');
        for ($attempt = 0; $attempt < 2; $attempt++) {
            $this->postJson(route('authentication.api.'.$endpoint), $endpoint === 'forgot-password' ? $this->forgot : $this->reset)
                ->assertInternalServerError()->assertHeader('Content-Type', 'application/vnd.api+json')
                ->assertExactJson(['errors' => [[
                    'title' => 'Erro interno do servidor', 'detail' => 'Não foi possível processar a solicitação.', 'status' => '500',
                ]]]);
        }
        $this->withoutExceptionHandling();
        try {
            expect(fn () => $this->postJson(route('authentication.api.'.$endpoint), []))->toThrow(RedisException::class);
        } finally {
            $this->withExceptionHandling();
        }
        expect([DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()])->toEqual($before);
        Queue::assertNothingPushed();
    } finally {
        $this->store->setConnection($original);
        app('redis')->purge('recovery_limiter_unavailable');
        config(['database.redis.recovery_limiter_unavailable' => null]);
    }
    expect((int) $this->limiter->attempts($key))->toBe(0)
        ->and(Cache::store('array')->get($key))->toBeNull();
    $this->postJson(route('authentication.api.'.$endpoint), $endpoint === 'forgot-password' ? $this->forgot : $this->reset)
        ->assertStatus($endpoint === 'forgot-password' ? 202 : 204);
    expect((int) $this->limiter->attempts($key))->toBe(1);
})->with(['forgot-password', 'reset-password'])->group('integration', 'redis');
