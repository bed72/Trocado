<?php

declare(strict_types=1);

use App\Identity\Application\Data\Input\ResetPasswordInput;
use App\Identity\Application\UseCases\ResetPasswordUseCase;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Notifications\PasswordChangedNotification;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Passwords\PasswordBrokerManager;
use Illuminate\Mail\Events\MessageSending;
use Illuminate\Notifications\Events\NotificationFailed;
use Illuminate\Queue\Events\JobExceptionOccurred;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Queue;
use Monolog\Formatter\JsonFormatter;
use Tests\Support\Core\Fixtures\ObservabilityLogFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;
use Tests\Support\Identity\Fixtures\PasswordRecoveryWorkerFixture;

beforeEach(function (): void {
    $this->originalExceptionArgs = ini_get('zend.exception_ignore_args');
    ini_set('zend.exception_ignore_args', '0');
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:00 UTC'));
    config([
        'identity.password_recovery.url' => null,
        'mail.default' => 'array', 'queue.default' => 'redis', 'queue.connections.redis.block_for' => null,
        'logging.default' => 'single', 'logging.channels.single.formatter' => JsonFormatter::class,
    ]);
    Log::forgetChannel('single');
    $this->observabilityLog = new ObservabilityLogFixture;
    $this->queue = config('queue.connections.redis.queue');
    $this->connection = Queue::connection('redis');
    $this->transport = Mail::mailer('array')->getSymfonyTransport();
    $this->worker = new PasswordRecoveryWorkerFixture($this->queue);
    $this->user = IdentityFixture::create(UserStatusEnum::Active, now());
    IdentityFixture::token($this->user, now()->addDays(30));
    $other = IdentityFixture::create(UserStatusEnum::Active, now(), email: 'other@example.com');
    IdentityFixture::token($other, now()->addDays(30));
    $token = app(PasswordBrokerManager::class)->broker('users')->getRepository()->create($this->user);
    $this->secrets = ['Correct1', 'Newpass1', 'PrivateConfirmation9', $token, $this->user->password, DB::table('password_reset_tokens')->sole()->token];
    app(ResetPasswordUseCase::class)->execute(new ResetPasswordInput('maria@example.com', $token, 'Newpass1'));
    $this->secrets[] = $this->user->fresh()->password;
    $this->committedState = [DB::table('users')->orderBy('id')->get()->all(), DB::table('personal_access_tokens')->orderBy('id')->get()->all(), DB::table('password_reset_tokens')->get()->all()];
});

afterEach(function (): void {
    try {
        $this->observabilityLog->close();
    } finally {
        ini_set('zend.exception_ignore_args', $this->originalExceptionArgs);
    }
});

it('delivers a credential free HTML and text notice only through the real Redis worker', function (): void {
    $payload = json_decode($this->connection->getConnection()->lindex('queues:'.$this->queue, 0), true, flags: JSON_THROW_ON_ERROR);
    $command = Crypt::decrypt($payload['data']['command']);
    $job = unserialize($command);
    expect($payload['displayName'])->toBe(PasswordChangedNotification::class)
        ->and($command)->not->toContain(...$this->secrets)
        ->and(json_encode($payload, JSON_THROW_ON_ERROR))->not->toContain(...[...$this->secrets, $this->user->email])
        ->and($job->notification)->toBeInstanceOf(PasswordChangedNotification::class)
        ->and($this->transport->messages())->toHaveCount(0)
        ->and($this->connection->pendingSize($this->queue))->toBe(1);

    $this->worker->work();

    $message = $this->transport->messages()->sole();
    $content = $message->getOriginalMessage();
    expect($message->getEnvelope()->getRecipients()[0]->getAddress())->toBe('maria@example.com')
        ->and($content->getSubject())->toBe('Sua senha foi alterada no Trocado')
        ->and($content->getHtmlBody())->toContain('Sua senha foi alterada', 'sessões anteriores foram encerradas', 'Se você não reconhece', '#2B6A46')
        ->and($content->getHtmlBody())->not->toContain('href=', ...$this->secrets)
        ->and($content->getTextBody())->toContain('Sua senha foi alterada', 'entre novamente', 'Se você não reconhece')
        ->and($content->getTextBody())->not->toContain(...$this->secrets)
        ->and($this->connection->size($this->queue))->toBe(0)->and(DB::table('failed_jobs')->count())->toBe(0)
        ->and([DB::table('users')->orderBy('id')->get()->all(), DB::table('personal_access_tokens')->orderBy('id')->get()->all(), DB::table('password_reset_tokens')->get()->all()])->toEqual($this->committedState);
})->group('integration', 'redis', 'worker');

it('discards a queued notice instead of delivering to a removed or changed recipient', function (bool $removed): void {
    if ($removed) {
        $this->user->delete();
    } else {
        $this->user->update(['email' => 'new@example.com']);
    }

    $this->worker->work();

    expect($this->transport->messages())->toHaveCount(0)->and($this->connection->size($this->queue))->toBe(0)
        ->and(DB::table('failed_jobs')->count())->toBe(0)->and(DB::table('password_reset_tokens')->count())->toBe(0);
})->with(['removed' => true, 'changed email' => false])->group('integration', 'redis', 'worker');

it('retries a failed notice without restoring the old credential recovery or revoked PATs', function (): void {
    $attempts = 0;
    Event::listen(MessageSending::class, function () use (&$attempts): void {
        if (++$attempts === 1) {
            throw new RuntimeException('Temporary notice transport failure.');
        }
    });

    $this->worker->work();
    expect($attempts)->toBe(1)->and($this->transport->messages())->toHaveCount(0)
        ->and($this->connection->size($this->queue))->toBe(1);
    $this->worker->work();
    expect($attempts)->toBe(2)->and($this->transport->messages())->toHaveCount(1)
        ->and($this->connection->size($this->queue))->toBe(0)->and(DB::table('failed_jobs')->count())->toBe(0)
        ->and([DB::table('users')->orderBy('id')->get()->all(), DB::table('personal_access_tokens')->orderBy('id')->get()->all(), DB::table('password_reset_tokens')->get()->all()])->toEqual($this->committedState);
})->group('integration', 'redis', 'worker');

it('sanitizes permanent notice failures before events logs and failed jobs without undoing the reset', function (): void {
    $payload = json_decode($this->connection->getConnection()->lindex('queues:'.$this->queue, 0), true, flags: JSON_THROW_ON_ERROR);
    $nativeFailures = [];
    $workerFailures = [];
    Event::listen(NotificationFailed::class, function (NotificationFailed $event) use (&$nativeFailures): void {
        $nativeFailures[] = $event->data['exception'];
    });
    Event::listen(JobExceptionOccurred::class, function (JobExceptionOccurred $event) use (&$workerFailures): void {
        $workerFailures[] = $event->exception;
    });
    $secrets = $this->secrets;
    Event::listen(MessageSending::class, static function () use ($secrets): never {
        throw new RuntimeException(implode(' ', $secrets));
    });

    $this->worker->work(tries: 2);
    $this->worker->work(tries: 2);

    expect($nativeFailures)->toHaveCount(2)->and($workerFailures)->toHaveCount(2);
    foreach ([...$nativeFailures, ...$workerFailures] as $failure) {
        expect($failure->getMessage())->toBe('Não foi possível entregar a notificação de recuperação de senha.')
            ->and($failure->getPrevious())->toBeNull()->and((string) $failure)->not->toContain(...$secrets);
    }
    $failed = DB::table('failed_jobs')->where('uuid', $payload['uuid'])->sole();
    $failedPayload = json_decode($failed->payload, true, flags: JSON_THROW_ON_ERROR);
    expect($failed->connection)->toBe('redis')->and($failed->queue)->toBe($this->queue)
        ->and($failedPayload['data']['command'])->toBe($payload['data']['command'])
        ->and(json_encode($failedPayload, JSON_THROW_ON_ERROR))->not->toContain(...$secrets)
        ->and($failed->exception)->not->toContain(...$secrets)
        ->and([DB::table('users')->orderBy('id')->get()->all(), DB::table('personal_access_tokens')->orderBy('id')->get()->all(), DB::table('password_reset_tokens')->get()->all()])->toEqual($this->committedState)
        ->and(Hash::check('Newpass1', $this->user->fresh()->password))->toBeTrue()
        ->and($this->user->tokens()->count())->toBe(0)->and(DB::table('password_reset_tokens')->count())->toBe(0)
        ->and($this->connection->size($this->queue))->toBe(0)->and($this->transport->messages())->toHaveCount(0);
    $records = $this->observabilityLog->records();
    $deliveryRecords = array_values(array_filter($records, fn (array $record): bool => $record['event'] === 'identity.password_recovery_delivery_failed'));
    expect($deliveryRecords)->toHaveCount(2);
    foreach ($deliveryRecords as $record) {
        expect(array_diff(array_keys($record), ['event', 'level', 'timestamp', 'trace_id', 'http_method', 'path', 'ip', 'user_id', 'exception_class']))->toBe([]);
    }
    $appLogs = array_map(static fn (string $line): array => json_decode($line, true, flags: JSON_THROW_ON_ERROR), file($this->resources->log, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES));
    expect($appLogs)->not->toBe([])
        ->and(json_encode(['observability' => $records, 'app' => $appLogs], JSON_THROW_ON_ERROR))->not->toContain(...$secrets);
})->group('integration', 'redis', 'worker');
