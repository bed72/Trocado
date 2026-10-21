<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Identity\Application\Data\Input\ResetPasswordInput;
use App\Identity\Application\Exceptions\CurrentPasswordException;
use App\Identity\Application\Exceptions\InvalidPasswordRecoveryException;
use App\Identity\Application\Ports\PasswordResetPort;
use App\Identity\Application\UseCases\ResetPasswordUseCase;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Adapters\PasswordRecoveryAdapter;
use App\Identity\Infrastructure\Adapters\PasswordRecoveryMailChannelAdapter;
use App\Identity\Infrastructure\Notifications\PasswordChangedNotification;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Passwords\PasswordBrokerManager;
use Illuminate\Contracts\Notifications\Dispatcher;
use Illuminate\Notifications\SendQueuedNotifications;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Queue;
use Tests\Support\Core\Spies\ObservabilityPortSpy;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:00 UTC'));
    config(['identity.password_recovery.url' => null, 'mail.default' => 'array', 'queue.default' => 'sync']);
    $this->observability = new ObservabilityPortSpy;
    app()->instance(ObservabilityPort::class, $this->observability);
    $this->user = IdentityFixture::create(UserStatusEnum::Active, now());
    IdentityFixture::token($this->user, now()->addDays(30));
    $this->native = app(PasswordBrokerManager::class)->broker('users')->getRepository();
    $this->token = $this->native->create($this->user);
    $this->input = new ResetPasswordInput(' MARIA@EXAMPLE.COM ', $this->token, 'Newpass1');
});

it('resolves the real reset port and queues a credential free notice only after commit without a reset URL', function (): void {
    Queue::fake();
    expect(app(PasswordResetPort::class))->toBeInstanceOf(PasswordRecoveryAdapter::class);
    DB::transaction(function (): void {
        app(ResetPasswordUseCase::class)->execute($this->input);
        expect(Hash::check('Newpass1', $this->user->fresh()->password))->toBeTrue()
            ->and($this->user->tokens()->count())->toBe(0)->and(DB::table('password_reset_tokens')->count())->toBe(0);
        Queue::assertNothingPushed();
    });

    Queue::assertPushed(SendQueuedNotifications::class, 1);
    $job = Queue::pushed(SendQueuedNotifications::class)->sole();
    expect($job->notification)->toBeInstanceOf(PasswordChangedNotification::class)
        ->and($job->connection)->toBe('redis')->and($job->afterCommit)->toBeTrue()
        ->and($job->deleteWhenMissingModels)->toBeTrue()->and($job->shouldBeEncrypted)->toBeTrue()
        ->and($job->channels)->toBe([PasswordRecoveryMailChannelAdapter::class])
        ->and(serialize($job->notification))->not->toContain('Newpass1', 'Correct1', $this->token, $this->user->password)
        ->and(Mail::mailer('array')->getSymfonyTransport()->messages())->toHaveCount(0)
        ->and($this->observability->events)->toBe([]);
});

it('rolls back all reset writes and never queues a notice for an aborted transaction', function (): void {
    Queue::fake();
    $before = [DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()];
    $failure = new RuntimeException('password-notice-rollback-sentinel');
    try {
        DB::transaction(function () use ($failure): never {
            app(ResetPasswordUseCase::class)->execute($this->input);
            expect(Hash::check('Newpass1', $this->user->fresh()->password))->toBeTrue()
                ->and($this->user->tokens()->count())->toBe(0)->and(DB::table('password_reset_tokens')->count())->toBe(0);
            Queue::assertNothingPushed();
            throw $failure;
        });
        $this->fail('Expected the original sentinel.');
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($failure);
    }
    expect([DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()])->toEqual($before)
        ->and($this->native->exists($this->user, $this->token))->toBeTrue();
    Queue::assertNothingPushed();
});

it('keeps the reset committed and sanitizes an enqueue failure after the transaction', function (): void {
    $dispatcher = $this->createMock(Dispatcher::class);
    $dispatcher->expects($this->once())->method('send')->willReturnCallback(
        function (object $user, PasswordChangedNotification $notification): never {
            expect(DB::transactionLevel())->toBe(0)->and(Hash::check('Newpass1', $user->password))->toBeTrue()
                ->and(DB::table('password_reset_tokens')->count())->toBe(0)->and($user->tokens()->count())->toBe(0);
            throw new RuntimeException('Private enqueue detail Newpass1 '.$this->token.' '.$user->password);
        },
    );
    app()->instance(Dispatcher::class, $dispatcher);

    expect(app(ResetPasswordUseCase::class)->execute($this->input))->toBeNull()
        ->and(Hash::check('Newpass1', $this->user->fresh()->password))->toBeTrue()
        ->and($this->user->tokens()->count())->toBe(0)->and(DB::table('password_reset_tokens')->count())->toBe(0)
        ->and($this->observability->events)->toBe([[
            'event' => 'identity.password_reset_queue_failed', 'attributes' => ['exception_class' => RuntimeException::class],
        ]]);
});

it('does not undo reset when the configured mailer is unsafe', function (): void {
    Queue::fake();
    config(['mail.default' => 'log']);

    expect(app(ResetPasswordUseCase::class)->execute($this->input))->toBeNull()
        ->and(Hash::check('Newpass1', $this->user->fresh()->password))->toBeTrue()
        ->and(DB::table('password_reset_tokens')->count())->toBe(0)->and($this->user->tokens()->count())->toBe(0)
        ->and($this->observability->events)->toBe([[
            'event' => 'identity.password_reset_queue_failed', 'attributes' => ['exception_class' => RuntimeException::class],
        ]]);
    Queue::assertNothingPushed();
});

it('does not enqueue a notice when the recipient no longer corresponds to the committed identity', function (bool $removed): void {
    Queue::fake();
    if ($removed) {
        $this->user->delete();
    } else {
        $this->user->update(['email' => 'new@example.com']);
    }

    app(PasswordResetPort::class)->requestNotice($this->user->getKey(), 'maria@example.com');

    Queue::assertNothingPushed();
    expect($this->observability->events)->toBe([]);
})->with(['removed' => true, 'changed' => false]);

it('does not enqueue notices for rejected reset attempts', function (bool $currentPassword): void {
    Queue::fake();
    $input = new ResetPasswordInput('maria@example.com', $currentPassword ? $this->token : 'wrong-token', $currentPassword ? 'Correct1' : 'Newpass1');
    expect(fn () => app(ResetPasswordUseCase::class)->execute($input))
        ->toThrow($currentPassword ? CurrentPasswordException::class : InvalidPasswordRecoveryException::class);
    Queue::assertNothingPushed();
    expect($this->native->exists($this->user, $this->token))->toBeTrue()
        ->and($this->user->tokens()->count())->toBe(1)->and(Hash::check('Correct1', $this->user->fresh()->password))->toBeTrue();
})->with(['current password' => true, 'invalid link' => false]);
