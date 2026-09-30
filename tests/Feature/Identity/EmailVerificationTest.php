<?php

declare(strict_types=1);

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\UseCases\SignUpUseCase;
use App\Identity\Application\UseCases\VerifyEmailUseCase;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;
use App\Identity\Infrastructure\Notifications\VerifyEmailNotification;
use App\Identity\Infrastructure\Repositories\Persistence\EloquentUserRepository;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Illuminate\Auth\Events\Verified;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Database\DeadlockException;
use Illuminate\Mail\Events\MessageSending;
use Illuminate\Mail\Transport\ArrayTransport;
use Illuminate\Notifications\ChannelManager;
use Illuminate\Notifications\Events\NotificationSent;
use Illuminate\Notifications\Events\NotificationSkipped;
use Illuminate\Notifications\SendQueuedNotifications;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\URL;

use function Pest\Laravel\withToken;

it('creates an unverified pending account and requests one queued verification', function (): void {
    Notification::fake();

    $response = $this->postJson(route('authentication.api.sign-up'), [
        'data' => [
            'type' => 'sign-ups',
            'attributes' => [
                'name' => 'Maria',
                'email' => 'maria@example.com',
                'password' => 'Correct1',
                'password_confirmation' => 'Correct1',
            ],
        ],
    ])->assertCreated();

    $user = UserModel::query()->findOrFail($response->json('data.relationships.user.data.id'));

    $response->assertHeader('Location', route('users.get', ['user' => $user->getKey()]))
        ->assertJsonPath('data.type', 'sign-ups');

    expect($user->status)->toBe(UserStatusEnum::Pending)
        ->and($user->email_verified_at)->toBeNull()
        ->and($user->tokens()->count())->toBe(0)
        ->and(Hash::check('Correct1', $user->password))->toBeTrue();
    Notification::assertSentTo($user, VerifyEmailNotification::class, 1);
});

it('does not request verification when registration is rolled back or conflicts', function (): void {
    Notification::fake();

    try {
        DB::transaction(function (): void {
            app(SignUpUseCase::class)->execute('Maria', 'maria@example.com', 'Correct1');

            throw new RuntimeException('Rollback proposital.');
        });
    } catch (RuntimeException $exception) {
        expect($exception->getMessage())->toBe('Rollback proposital.');
    }

    expect(UserModel::query()->count())->toBe(0);
    Notification::assertNothingSent();

    $payload = ['data' => ['type' => 'sign-ups', 'attributes' => [
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Correct1',
        'password_confirmation' => 'Correct1',
    ]]];

    $this->postJson(route('authentication.api.sign-up'), $payload)->assertCreated();
    $this->postJson(route('authentication.api.sign-up'), $payload)->assertConflict();

    expect(UserModel::query()->count())->toBe(1);
    Notification::assertCount(1);
});

it('retries a transient concurrency error during registration without duplicating the account or email', function (): void {
    Notification::fake();
    $attempts = 0;

    UserModel::creating(function (UserModel $user) use (&$attempts): void {
        $attempts++;

        if ($attempts === 1) {
            throw new DeadlockException('deadlock detected');
        }
    });

    $userId = app(SignUpUseCase::class)->execute(
        name: 'Maria',
        email: 'maria@example.com',
        password: 'Correct1',
    );

    expect($attempts)->toBe(2)
        ->and(UserModel::query()->where('email', 'maria@example.com')->count())->toBe(1);
    Notification::assertSentTo(UserModel::query()->findOrFail($userId), VerifyEmailNotification::class, 1);
});

it('discards the verification callback from a transaction attempt rolled back after registration', function (): void {
    Notification::fake();
    $attempts = 0;

    $this->app->instance(TransactionPort::class, new class($attempts) implements TransactionPort
    {
        public function __construct(private int &$attempts) {}

        public function commit(callable $operation): mixed
        {
            return DB::transaction(function () use ($operation): mixed {
                $result = $operation();
                $this->attempts++;

                if ($this->attempts === 1) {
                    throw new DeadlockException('deadlock detected after callback registration');
                }

                return $result;
            }, attempts: 3);
        }

        public function afterCommit(callable $callback): void
        {
            DB::afterCommit($callback);
        }
    });

    $userId = app(SignUpUseCase::class)->execute('Maria', 'maria@example.com', 'Correct1');

    expect($attempts)->toBe(2)
        ->and(UserModel::query()->where('email', 'maria@example.com')->count())->toBe(1);
    Notification::assertSentTo(UserModel::query()->findOrFail($userId), VerifyEmailNotification::class, 1);
});

it('does not retry or expose unrelated persistence errors', function (): void {
    Notification::fake();
    $attempts = 0;

    UserModel::creating(function (UserModel $user) use (&$attempts): void {
        $attempts++;

        throw new RuntimeException('internal persistence failure');
    });

    expect(fn (): int => app(SignUpUseCase::class)->execute(
        name: 'Maria',
        email: 'maria@example.com',
        password: 'Correct1',
    ))->toThrow(RuntimeException::class, 'Não foi possível persistir a nova conta.');

    expect($attempts)->toBe(1)
        ->and(UserModel::query()->count())->toBe(0);
    Notification::assertNothingSent();
});

it('skips a queued notification if the email changed before the worker sends it', function (): void {
    Queue::fake();
    Event::fake([NotificationSent::class, NotificationSkipped::class]);
    $user = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'old@example.com',
        'password' => 'Correct1',
    ]);
    $user->sendEmailVerificationNotification();
    Queue::assertPushed(SendQueuedNotifications::class, 1);

    UserModel::query()->whereKey($user->getKey())->update(['email' => 'new@example.com']);
    $job = unserialize(serialize(Queue::pushed(SendQueuedNotifications::class)->sole()));
    $job->handle(app(ChannelManager::class));

    expect($job->notification)->toBeInstanceOf(ShouldQueue::class)
        ->and($job->deleteWhenMissingModels)->toBeTrue();
    Event::assertDispatchedTimes(NotificationSkipped::class, 1);
    Event::assertNotDispatched(NotificationSent::class);
});

it('delivers a signed expiring verification link when the queued job is processed', function (): void {
    Queue::fake();
    Event::fake([NotificationSent::class]);
    $user = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Correct1',
    ]);
    $user->sendEmailVerificationNotification();

    $job = unserialize(serialize(Queue::pushed(SendQueuedNotifications::class)->sole()));
    $job->handle(app(ChannelManager::class));

    Event::assertDispatchedTimes(NotificationSent::class, 1);
    $frontendUrl = $job->notification->toMail($user)->actionUrl;
    expect($frontendUrl)->toStartWith(rtrim(config('app.url'), '/').'/authentication/confirm-email?verification_url=');

    parse_str((string) parse_url($frontendUrl, PHP_URL_QUERY), $parameters);
    $url = $parameters['verification_url'];
    expect($url)->toContain('email-verification/', 'signature=', 'expires=');

    $this->travel(61)->minutes();
    $this->getJson($url)->assertForbidden();
    expect($user->refresh()->email_verified_at)->toBeNull();
});

it('delivers verification through the real Redis worker and retries a temporary mail failure', function (): void {
    $queue = 'identity-verification-test-'.bin2hex(random_bytes(8));
    config()->set('queue.default', 'redis');
    config()->set('queue.connections.redis.queue', $queue);
    $transport = Mail::mailer('array')->getSymfonyTransport();
    expect($transport)->toBeInstanceOf(ArrayTransport::class);

    $attempts = 0;
    Event::listen(MessageSending::class, function () use (&$attempts): void {
        $attempts++;

        if ($attempts === 1) {
            throw new RuntimeException('Temporary mail failure.');
        }
    });

    $response = $this->postJson(route('authentication.api.sign-up'), [
        'data' => ['type' => 'sign-ups', 'attributes' => [
            'name' => 'Maria',
            'email' => 'maria@example.com',
            'password' => 'Correct1',
            'password_confirmation' => 'Correct1',
        ]],
    ])->assertCreated();

    $user = UserModel::query()->findOrFail($response->json('data.relationships.user.data.id'));
    expect($transport->messages())->toHaveCount(0)
        ->and(Queue::connection('redis')->size($queue))->toBe(1);

    Artisan::call('queue:work', ['connection' => 'redis', '--queue' => $queue, '--once' => true, '--tries' => 3, '--backoff' => 0]);

    expect($attempts)->toBe(1)
        ->and($transport->messages())->toHaveCount(0)
        ->and(Queue::connection('redis')->size($queue))->toBe(1)
        ->and($user->fresh()->email_verified_at)->toBeNull();

    Artisan::call('queue:work', ['connection' => 'redis', '--queue' => $queue, '--once' => true, '--tries' => 3, '--backoff' => 0]);

    expect($attempts)->toBe(2)
        ->and($transport->messages())->toHaveCount(1)
        ->and(Queue::connection('redis')->size($queue))->toBe(0)
        ->and($user->fresh()->status)->toBe(UserStatusEnum::Pending);

    $message = $transport->messages()->sole();
    expect($message->getEnvelope()->getRecipients()[0]->getAddress())->toBe('maria@example.com')
        ->and($message->getOriginalMessage()->getHtmlBody())->toContain('/authentication/confirm-email', 'verification_url=');

    $changed = UserModel::query()->create([
        'name' => 'Ana',
        'email' => 'old@example.com',
        'password' => 'Correct1',
    ]);
    $changed->sendEmailVerificationNotification();
    $changed->update(['email' => 'new@example.com']);

    Artisan::call('queue:work', ['connection' => 'redis', '--queue' => $queue, '--once' => true]);

    expect($transport->messages())->toHaveCount(1)
        ->and(Queue::connection('redis')->size($queue))->toBe(0)
        ->and($changed->fresh()->email_verified_at)->toBeNull();

    $deleted = UserModel::query()->create([
        'name' => 'Bruna',
        'email' => 'removed@example.com',
        'password' => 'Correct1',
    ]);
    $deleted->sendEmailVerificationNotification();
    $deleted->delete();

    Artisan::call('queue:work', ['connection' => 'redis', '--queue' => $queue, '--once' => true]);

    expect($transport->messages())->toHaveCount(1)
        ->and(Queue::connection('redis')->size($queue))->toBe(0);
});

it('verifies an email through a public signed link without activating the account', function (): void {
    Event::fake([Verified::class]);
    $user = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Correct1',
        'status' => UserStatusEnum::Pending,
    ]);
    $url = URL::temporarySignedRoute(
        name: 'verification.verify',
        expiration: now()->addHour(),
        parameters: ['id' => $user->getKey(), 'hash' => sha1($user->email)],
    );

    $this->getJson($url)->assertNoContent();
    $verifiedAt = $user->refresh()->email_verified_at;

    expect($verifiedAt)->not->toBeNull()
        ->and($user->status)->toBe(UserStatusEnum::Pending)
        ->and($user->tokens()->count())->toBe(0);
    Event::assertDispatchedTimes(Verified::class, 1);

    $this->getJson($url)->assertNoContent();

    expect($user->refresh()->email_verified_at->equalTo($verifiedAt))->toBeTrue();
    Event::assertDispatchedTimes(Verified::class, 1);
});

it('rejects invalid verification links uniformly', function (): void {
    $user = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Correct1',
    ]);
    $url = URL::temporarySignedRoute(
        name: 'verification.verify',
        expiration: now()->addHour(),
        parameters: ['id' => $user->getKey(), 'hash' => sha1('old@example.com')],
    );

    $this->getJson($url)
        ->assertForbidden()
        ->assertHeader('Content-Type', 'application/vnd.api+json');

    $this->getJson($url.'&tampered=1')
        ->assertForbidden()
        ->assertHeader('Content-Type', 'application/vnd.api+json');

    $expired = URL::temporarySignedRoute(
        name: 'verification.verify',
        expiration: now()->subMinute(),
        parameters: ['id' => $user->getKey(), 'hash' => sha1($user->email)],
    );
    $this->getJson($expired)->assertForbidden()->assertHeader('Content-Type', 'application/vnd.api+json');

    $missing = URL::temporarySignedRoute(
        name: 'verification.verify',
        expiration: now()->addHour(),
        parameters: ['id' => $user->getKey() + 1, 'hash' => sha1($user->email)],
    );
    $this->getJson($missing)->assertForbidden()->assertHeader('Content-Type', 'application/vnd.api+json');

    expect($user->refresh()->email_verified_at)->toBeNull();
});

it('confirms a blocked user email without granting access', function (): void {
    $user = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Correct1',
        'status' => UserStatusEnum::Blocked,
    ]);
    $url = URL::temporarySignedRoute(
        name: 'verification.verify',
        expiration: now()->addHour(),
        parameters: ['id' => $user->getKey(), 'hash' => sha1($user->email)],
    );

    $this->getJson($url)->assertNoContent();

    expect($user->refresh()->hasVerifiedEmail())->toBeTrue()
        ->and($user->status)->toBe(UserStatusEnum::Blocked)
        ->and($user->tokens()->count())->toBe(0);
});

it('does not emit verification events for a rolled back confirmation', function (): void {
    Event::fake([Verified::class]);
    $user = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Correct1',
    ]);

    try {
        DB::transaction(function () use ($user): void {
            app(VerifyEmailUseCase::class)->execute(
                userId: (int) $user->getKey(),
                hash: sha1($user->email),
            );

            throw new RuntimeException('Rollback proposital.');
        });
    } catch (RuntimeException $exception) {
        expect($exception->getMessage())->toBe('Rollback proposital.');
    }

    expect($user->refresh()->email_verified_at)->toBeNull();
    Event::assertNotDispatched(Verified::class);
});

it('requires both active status and a verified email before issuing a token', function (): void {
    $user = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Correct1',
        'status' => UserStatusEnum::Active,
    ]);

    $this->postJson(route('authentication.api.sign-in'), [
        'data' => [
            'type' => 'access-tokens',
            'attributes' => ['email' => $user->email, 'password' => 'Correct1'],
        ],
    ])->assertForbidden()->assertJsonPath('errors.0.title', 'E-mail não confirmado');

    expect($user->tokens()->count())->toBe(0);

    $user->markEmailAsVerified();

    $this->postJson(route('authentication.api.sign-in'), [
        'data' => [
            'type' => 'access-tokens',
            'attributes' => ['email' => $user->email, 'password' => 'Correct1'],
        ],
    ])->assertOk();
});

it('rejects an existing token on protected routes after verification is cleared', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    UserModel::query()->whereKey($userId)->update(['email_verified_at' => null]);

    Auth::forgetGuards();
    withToken($token)->getJson(route('users.get', ['user' => $userId]))
        ->assertForbidden()
        ->assertHeader('Content-Type', 'application/vnd.api+json');

    Auth::forgetGuards();
    withToken($token)->getJson(route('expenses.index'))
        ->assertForbidden()
        ->assertHeader('Content-Type', 'application/vnd.api+json');
});

it('resends uniformly only for an existing unverified account', function (): void {
    Notification::fake();
    $user = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Correct1',
    ]);
    $payload = fn (string $email): array => [
        'data' => [
            'type' => 'email-verifications',
            'attributes' => ['email' => $email],
        ],
    ];

    $this->postJson(route('authentication.api.email-verification.resend'), $payload($user->email))
        ->assertAccepted();
    $this->postJson(route('authentication.api.email-verification.resend'), $payload('unknown@example.com'))
        ->assertAccepted();

    Notification::assertSentTo($user, VerifyEmailNotification::class, 1);
});

it('does not disclose whether a resend address is registered or already verified', function (): void {
    Notification::fake();
    $verified = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Correct1',
    ]);
    $verified->markEmailAsVerified();

    foreach (['maria@example.com', 'unknown@example.com'] as $email) {
        $this->postJson(route('authentication.api.email-verification.resend'), [
            'data' => ['type' => 'email-verifications', 'attributes' => ['email' => $email]],
        ])->assertAccepted();
    }

    Notification::assertNothingSent();
});

it('limits resend independently by IP and email', function (): void {
    Notification::fake();
    $payload = fn (string $email): array => [
        'data' => ['type' => 'email-verifications', 'attributes' => ['email' => $email]],
    ];

    $this->postJson(route('authentication.api.email-verification.resend'), $payload('maria@example.com'))->assertAccepted();
    $this->postJson(route('authentication.api.email-verification.resend'), $payload('maria@example.com'))->assertAccepted();
    $this->postJson(route('authentication.api.email-verification.resend'), $payload('maria@example.com'))
        ->assertTooManyRequests()
        ->assertHeader('Retry-After')
        ->assertHeader('Content-Type', 'application/vnd.api+json');

    foreach (['ana', 'bruna', 'carla'] as $name) {
        $this->postJson(route('authentication.api.email-verification.resend'), $payload("$name@example.com"))
            ->assertAccepted();
    }

    $this->postJson(route('authentication.api.email-verification.resend'), $payload('dora@example.com'))
        ->assertTooManyRequests();

    $this->postJson(route('authentication.api.sign-up'), [
        'data' => ['type' => 'sign-ups', 'attributes' => []],
    ])->assertUnprocessable();
    $this->postJson(route('authentication.api.sign-in'), [
        'data' => ['type' => 'access-tokens', 'attributes' => [
            'email' => 'unknown@example.com',
            'password' => 'Correct1',
        ]],
    ])->assertUnauthorized();

    Notification::assertNothingSent();
});

it('rejects email edits without changing verification or tokens', function (string $email): void {
    Notification::fake();
    $userId = signUpIdentityByApi($this);
    $firstToken = signInIdentityByApi($this);
    $user = UserModel::query()->findOrFail($userId);
    $user->createToken(name: 'second');
    $verifiedAt = $user->email_verified_at;
    Notification::fake();

    withToken($firstToken)->patchJson(route('users.update', ['user' => $userId]), [
        'data' => [
            'type' => 'users',
            'id' => (string) $userId,
            'attributes' => ['email' => $email],
        ],
    ])->assertUnprocessable()->assertJsonPath('errors.0.source.pointer', '/data/attributes');

    $user->refresh();

    expect($user->email)->toBe('maria@example.com')
        ->and($user->email_verified_at->equalTo($verifiedAt))->toBeTrue()
        ->and($user->tokens()->count())->toBe(2);
    Notification::assertNothingSent();

    Auth::forgetGuards();
    withToken($firstToken)->getJson(route('users.get', ['user' => $userId]))->assertOk();
})->with(['nova@example.com', ' MARIA@EXAMPLE.COM ']);

it('never persists an email change through the user repository update', function (): void {
    $user = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Correct1',
    ]);

    app(EloquentUserRepository::class)->update(new UserEntity(
        id: (int) $user->getKey(),
        name: NameValueObject::fromString(value: 'Maria Souza'),
        email: EmailValueObject::fromString(value: 'nova@example.com'),
    ));

    expect($user->refresh()->name)->toBe('Maria Souza')
        ->and($user->email)->toBe('maria@example.com');
});

it('does not allow editing the name of another user', function (): void {
    $ownerId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $other = UserModel::query()->create([
        'name' => 'Ana',
        'email' => 'ana@example.com',
        'password' => 'Correct1',
    ]);

    withToken($token)->patchJson(route('users.update', ['user' => $other->getKey()]), [
        'data' => [
            'type' => 'users',
            'id' => (string) $other->getKey(),
            'attributes' => ['name' => 'Ana Souza'],
        ],
    ])->assertNotFound();

    expect($other->refresh()->name)->toBe('Ana')
        ->and(UserModel::query()->findOrFail($ownerId)->tokens()->count())->toBe(1);
});

it('preserves verification and tokens when editing only the name', function (): void {
    Notification::fake();
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $user = UserModel::query()->findOrFail($userId);
    $verifiedAt = $user->email_verified_at;
    Notification::fake();

    withToken($token)->patchJson(route('users.update', ['user' => $userId]), [
        'data' => [
            'type' => 'users',
            'id' => (string) $userId,
            'attributes' => ['name' => 'Maria Souza'],
        ],
    ])->assertOk()->assertJsonPath('data.attributes.name', 'Maria Souza');

    $user->refresh();

    expect($user->email_verified_at->equalTo($verifiedAt))->toBeTrue()
        ->and($user->tokens()->count())->toBe(1);
    Notification::assertNothingSent();
});
