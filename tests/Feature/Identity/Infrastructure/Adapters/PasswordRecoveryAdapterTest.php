<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Identity\Application\Ports\PasswordRecoveryPort;
use App\Identity\Application\UseCases\RequestPasswordRecoveryUseCase;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Adapters\PasswordRecoveryMailChannelAdapter;
use App\Identity\Infrastructure\Notifications\PasswordRecoveryNotification;
use Carbon\CarbonImmutable;
use Illuminate\Contracts\Notifications\Dispatcher;
use Illuminate\Mail\Transport\LogTransport;
use Illuminate\Notifications\SendQueuedNotifications;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Queue;
use Psr\Log\LoggerInterface;
use Tests\Support\Core\Spies\ObservabilityPortSpy;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:00 UTC'));
    config(['identity.password_recovery.url' => 'https://app.example.com/reset?locale=pt-BR', 'mail.default' => 'array']);
    $this->observability = new ObservabilityPortSpy;
    app()->instance(ObservabilityPort::class, $this->observability);
});

it('resolves the real port and queues an encrypted notification after commit without sending in the caller', function (): void {
    Queue::fake();
    $user = IdentityFixture::create(UserStatusEnum::Active, now(), email: 'maria+tag@example.com');
    request()->headers->set('Host', 'attacker.example');
    config(['app.url' => 'https://attacker.example']);

    expect(app(RequestPasswordRecoveryUseCase::class)->execute(' MARIA+TAG@EXAMPLE.COM '))->toBeNull();

    Queue::assertPushed(SendQueuedNotifications::class, 1);
    $job = Queue::pushed(SendQueuedNotifications::class)->sole();
    expect($job->notification)->toBeInstanceOf(PasswordRecoveryNotification::class)
        ->and($job->shouldBeEncrypted)->toBeTrue()
        ->and($job->deleteWhenMissingModels)->toBeTrue()
        ->and($job->afterCommit)->toBeTrue()
        ->and($job->connection)->toBe('redis')
        ->and($job->channels)->toBe([PasswordRecoveryMailChannelAdapter::class])
        ->and(Mail::mailer('array')->getSymfonyTransport()->messages())->toHaveCount(0);
    $url = $job->notification->toMail($user)->actionUrl;
    parse_str(parse_url($url, PHP_URL_QUERY), $query);
    expect($url)->toStartWith('https://app.example.com/reset?locale=pt-BR&')
        ->and($query['email'])->toBe('maria+tag@example.com')
        ->and(Hash::check($query['token'], DB::table('password_reset_tokens')->value('token')))->toBeTrue()
        ->and($this->observability->events)->toBe([]);
});

it('does not queue a real notification when the emission is rolled back', function (): void {
    Queue::fake();
    IdentityFixture::create(UserStatusEnum::Active, now());
    $failure = new RuntimeException('recovery-queue-rollback-sentinel');

    try {
        DB::transaction(function () use ($failure): never {
            app(RequestPasswordRecoveryUseCase::class)->execute('maria@example.com');
            expect(DB::table('password_reset_tokens')->count())->toBe(1);
            Queue::assertNothingPushed();
            throw $failure;
        });
        $this->fail('The sentinel must propagate.');
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($failure);
    }
    Queue::assertNothingPushed();
    expect(DB::table('password_reset_tokens')->count())->toBe(0)->and($this->observability->events)->toBe([]);
});

it('rejects unavailable URL configuration uniformly before issuing for an eligible or missing account', function (?string $url): void {
    Queue::fake();
    config(['identity.password_recovery.url' => $url]);
    IdentityFixture::create(UserStatusEnum::Active, now());

    foreach (['maria@example.com', 'missing@example.com'] as $email) {
        expect(app(RequestPasswordRecoveryUseCase::class)->execute($email))->toBeNull();
    }

    expect(DB::table('password_reset_tokens')->count())->toBe(0)
        ->and($this->observability->events)->toBe(array_fill(0, 2, [
            'event' => 'identity.password_recovery_unavailable', 'attributes' => ['exception_class' => RuntimeException::class],
        ]));
    Queue::assertNothingPushed();
})->with([null, 'https://app.example.com/reset?token=private', 'https://user:private@app.example.com/reset']);

it('refuses logging composite and unknown mailers instead of exposing credential bearing mail', function (string $mailer): void {
    Queue::fake();
    config(['mail.default' => $mailer]);
    if ($mailer === 'smtp-url-log') {
        config(['mail.default' => 'smtp', 'mail.mailers.smtp.url' => 'log://default']);
    }
    IdentityFixture::create(UserStatusEnum::Active, now());

    expect(app(RequestPasswordRecoveryUseCase::class)->execute('maria@example.com'))->toBeNull()
        ->and(DB::table('password_reset_tokens')->count())->toBe(0)
        ->and($this->observability->events)->toHaveCount(1)
        ->and($this->observability->events[0]['event'])->toBe('identity.password_recovery_unavailable');
    Queue::assertNothingPushed();
})->with(['log', 'failover', 'roundrobin', 'unknown', 'smtp-url-log']);

it('also refuses a cached unsafe transport hidden behind otherwise permitted configuration', function (bool $composite): void {
    Queue::fake();
    if ($composite) {
        config(['mail.default' => 'recovery-cached', 'mail.mailers.recovery-cached' => ['transport' => 'failover', 'mailers' => ['array']]]);
        Mail::mailer()->getSymfonyTransport();
        config(['mail.mailers.recovery-cached' => ['transport' => 'array']]);
    } else {
        $logger = $this->createMock(LoggerInterface::class);
        $logger->expects($this->never())->method('debug');
        Mail::mailer('array')->setSymfonyTransport(new LogTransport($logger));
    }
    IdentityFixture::create(UserStatusEnum::Active, now());

    expect(app(RequestPasswordRecoveryUseCase::class)->execute('maria@example.com'))->toBeNull()
        ->and(DB::table('password_reset_tokens')->count())->toBe(0);
    Queue::assertNothingPushed();
})->with(['composite' => true, 'logging' => false]);

it('preserves a committed token after enqueue failure and permits another attempt only after the interval', function (): void {
    IdentityFixture::create(UserStatusEnum::Active, now());
    $dispatcher = $this->createMock(Dispatcher::class);
    $dispatcher->expects($this->exactly(2))->method('send')->willReturnCallback(
        function (object $user, PasswordRecoveryNotification $notification): never {
            throw new RuntimeException('Private enqueue detail '.$notification->toMail($user)->actionUrl);
        },
    );
    app()->instance(Dispatcher::class, $dispatcher);

    expect(app(RequestPasswordRecoveryUseCase::class)->execute('maria@example.com'))->toBeNull();
    $before = (array) DB::table('password_reset_tokens')->sole();
    app(RequestPasswordRecoveryUseCase::class)->execute('maria@example.com');
    expect((array) DB::table('password_reset_tokens')->sole())->toBe($before);
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:01:00 UTC'));
    app(RequestPasswordRecoveryUseCase::class)->execute('maria@example.com');

    expect(DB::table('password_reset_tokens')->value('token'))->not->toBe($before['token'])
        ->and($this->observability->events)->toBe(array_fill(0, 2, [
            'event' => 'identity.password_recovery_queue_failed', 'attributes' => ['exception_class' => RuntimeException::class],
        ]));
});

it('skips enqueue if the expected recipient no longer matches or has been removed', function (bool $removed): void {
    Queue::fake();
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    if ($removed) {
        $user->delete();
    } else {
        $user->update(['email' => 'new@example.com']);
    }

    app(PasswordRecoveryPort::class)->requestLink($user->getKey(), 'maria@example.com', 'test-only-token');

    Queue::assertNothingPushed();
})->with(['removed' => true, 'changed' => false]);
