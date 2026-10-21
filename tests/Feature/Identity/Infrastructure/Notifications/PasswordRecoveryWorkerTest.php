<?php

declare(strict_types=1);

use App\Identity\Application\UseCases\RequestPasswordRecoveryUseCase;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Notifications\PasswordRecoveryNotification;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Passwords\PasswordBrokerManager;
use Illuminate\Mail\Events\MessageSending;
use Illuminate\Notifications\Events\NotificationFailed;
use Illuminate\Notifications\SendQueuedNotifications;
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
        'identity.password_recovery.url' => 'https://app.example.com/reset?locale=pt-BR',
        'mail.default' => 'array', 'queue.default' => 'redis', 'queue.connections.redis.block_for' => null,
        'logging.default' => 'single', 'logging.channels.single.formatter' => JsonFormatter::class,
    ]);
    Log::forgetChannel('single');
    $this->observabilityLog = new ObservabilityLogFixture;
    $this->queue = config('queue.connections.redis.queue');
    $this->connection = Queue::connection('redis');
    $this->transport = Mail::mailer('array')->getSymfonyTransport();
    $this->worker = new PasswordRecoveryWorkerFixture($this->queue);
});

afterEach(function (): void {
    try {
        $this->observabilityLog->close();
    } finally {
        ini_set('zend.exception_ignore_args', $this->originalExceptionArgs);
    }
});

it('stores an encrypted command and delivers the captured link only when the real Redis worker processes it', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now(), email: 'maria+tag@example.com');
    app(RequestPasswordRecoveryUseCase::class)->execute(' MARIA+TAG@EXAMPLE.COM ');
    $record = (array) DB::table('password_reset_tokens')->sole();
    $payload = json_decode($this->connection->getConnection()->lindex('queues:'.$this->queue, 0), true, flags: JSON_THROW_ON_ERROR);
    $job = unserialize(Crypt::decrypt($payload['data']['command']));
    $url = $job->notification->toMail($user)->actionUrl;
    parse_str(parse_url($url, PHP_URL_QUERY), $query);

    expect($this->transport->messages())->toHaveCount(0)
        ->and($this->connection->pendingSize($this->queue))->toBe(1)
        ->and($payload['displayName'])->toBe(PasswordRecoveryNotification::class)
        ->and($payload['data']['commandName'])->toBe(SendQueuedNotifications::class)
        ->and($payload['data']['command'])->not->toStartWith('O:')
        ->and($payload['data']['command'])->not->toContain($url, $query['token'], $user->email)
        ->and(json_encode($payload, JSON_THROW_ON_ERROR))->not->toContain($url, $query['token'], $record['token'], $user->email)
        ->and($query['email'])->toBe('maria+tag@example.com')
        ->and($query['locale'])->toBe('pt-BR')
        ->and(Hash::check($query['token'], $record['token']))->toBeTrue();

    $this->worker->work();

    expect($this->transport->messages())->toHaveCount(1)
        ->and($this->connection->size($this->queue))->toBe(0)
        ->and(DB::table('failed_jobs')->count())->toBe(0)
        ->and((array) DB::table('password_reset_tokens')->sole())->toBe($record);
    $message = $this->transport->messages()->sole();
    expect($message->getEnvelope()->getRecipients()[0]->getAddress())->toBe('maria+tag@example.com')
        ->and($message->getOriginalMessage()->getSubject())->toBe('Recuperação de senha do Trocado')
        ->and($message->getOriginalMessage()->getTextBody())->toContain(
            $url, 'Redefina sua senha', '30 minutos a partir da solicitação', 'Se você não solicitou',
        )
        ->and($message->getOriginalMessage()->getHtmlBody())->toContain(
            'href="'.e($url).'"', 'Redefinir senha', '30 minutos a partir da solicitação', 'Se você não solicitou', '#2B6A46',
        );
})->group('integration', 'redis', 'worker');

it('discards queued delivery after the account is removed or its address changes', function (bool $removed): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    app(RequestPasswordRecoveryUseCase::class)->execute('maria@example.com');
    if ($removed) {
        $user->delete();
    } else {
        $user->update(['email' => 'new@example.com']);
    }

    $this->worker->work();

    expect($this->transport->messages())->toHaveCount(0)
        ->and($this->connection->size($this->queue))->toBe(0)
        ->and(DB::table('failed_jobs')->count())->toBe(0);
})->with(['removed' => true, 'changed email' => false])->group('integration', 'redis', 'worker');

it('does not regenerate or refresh a rotated or expired link when an old queued job is delayed', function (bool $rotate): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    app(RequestPasswordRecoveryUseCase::class)->execute('maria@example.com');
    $first = (array) DB::table('password_reset_tokens')->sole();
    $this->travelTo(CarbonImmutable::parse($rotate ? '2026-10-21 12:01:00 UTC' : '2026-10-21 12:31:00 UTC'));
    if ($rotate) {
        app(RequestPasswordRecoveryUseCase::class)->execute('maria@example.com');
    }
    $beforeWorker = (array) DB::table('password_reset_tokens')->sole();

    $this->worker->work();

    $message = $this->transport->messages()->sole()->getOriginalMessage();
    preg_match('~https://app\.example\.com/reset\?[^\s)]+~', $message->getTextBody(), $matches);
    parse_str(parse_url($matches[0], PHP_URL_QUERY), $query);
    expect(Hash::check($query['token'], $first['token']))->toBeTrue()
        ->and(app(PasswordBrokerManager::class)->broker('users')->getRepository()->exists($user, $query['token']))->toBeFalse()
        ->and((array) DB::table('password_reset_tokens')->sole())->toBe($beforeWorker);
})->with(['rotated' => true, 'expired' => false])->group('integration', 'redis', 'worker');

it('retries a temporary transport failure without replacing the committed recovery', function (): void {
    IdentityFixture::create(UserStatusEnum::Active, now());
    $attempts = 0;
    Event::listen(MessageSending::class, function () use (&$attempts): void {
        if (++$attempts === 1) {
            throw new RuntimeException('Temporary transport failure.');
        }
    });
    app(RequestPasswordRecoveryUseCase::class)->execute('maria@example.com');
    $before = (array) DB::table('password_reset_tokens')->sole();

    $this->worker->work();
    expect($attempts)->toBe(1)->and($this->transport->messages())->toHaveCount(0)
        ->and($this->connection->size($this->queue))->toBe(1);
    $this->worker->work();
    expect($attempts)->toBe(2)->and($this->transport->messages())->toHaveCount(1)
        ->and($this->connection->size($this->queue))->toBe(0)
        ->and(DB::table('failed_jobs')->count())->toBe(0)
        ->and((array) DB::table('password_reset_tokens')->sole())->toBe($before);
})->group('integration', 'redis', 'worker');

it('protects failed job payload exceptions native failure events and structured logs even when transport errors contain secrets', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    app(RequestPasswordRecoveryUseCase::class)->execute('maria@example.com');
    $before = (array) DB::table('password_reset_tokens')->sole();
    $queued = json_decode($this->connection->getConnection()->lindex('queues:'.$this->queue, 0), true, flags: JSON_THROW_ON_ERROR);
    $job = unserialize(Crypt::decrypt($queued['data']['command']));
    $url = $job->notification->toMail($user)->actionUrl;
    parse_str(parse_url($url, PHP_URL_QUERY), $query);
    $secrets = [$url, $query['token'], $before['token'], 'PrivatePassword9', 'PrivateConfirmation9'];
    $nativeFailures = [];
    $workerFailures = [];
    Event::listen(NotificationFailed::class, function (NotificationFailed $event) use (&$nativeFailures): void {
        $nativeFailures[] = $event->data['exception'];
    });
    Event::listen(JobExceptionOccurred::class, function (JobExceptionOccurred $event) use (&$workerFailures): void {
        $workerFailures[] = $event->exception;
    });
    Event::listen(MessageSending::class, static function () use ($secrets): never {
        throw new RuntimeException(implode(' ', $secrets));
    });

    $this->worker->work(tries: 2);
    $this->worker->work(tries: 2);

    expect($nativeFailures)->toHaveCount(2)->and($workerFailures)->toHaveCount(2);
    foreach ([...$nativeFailures, ...$workerFailures] as $failure) {
        expect($failure->getMessage())->toBe('Não foi possível entregar a notificação de recuperação de senha.')
            ->and($failure->getPrevious())->toBeNull()
            ->and((string) $failure)->not->toContain(...$secrets);
    }
    $failed = DB::table('failed_jobs')->where('uuid', $queued['uuid'])->sole();
    $failedPayload = json_decode($failed->payload, true, flags: JSON_THROW_ON_ERROR);
    expect($failed->connection)->toBe('redis')->and($failed->queue)->toBe($this->queue)
        ->and($failedPayload['data']['command'])->toBe($queued['data']['command'])
        ->and(json_encode($failedPayload, JSON_THROW_ON_ERROR))->not->toContain(...$secrets)
        ->and($failed->exception)->not->toContain(...$secrets)
        ->and((array) DB::table('password_reset_tokens')->sole())->toBe($before)
        ->and($this->connection->size($this->queue))->toBe(0)
        ->and($this->transport->messages())->toHaveCount(0);
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

it('blocks a switch to logging transport before the worker can expose its queued credential', function (): void {
    IdentityFixture::create(UserStatusEnum::Active, now());
    app(RequestPasswordRecoveryUseCase::class)->execute('maria@example.com');
    $before = (array) DB::table('password_reset_tokens')->sole();
    config(['mail.default' => 'log']);

    $this->worker->work(tries: 1);

    expect($this->transport->messages())->toHaveCount(0)
        ->and(DB::table('failed_jobs')->where('queue', $this->queue)->count())->toBe(1)
        ->and((array) DB::table('password_reset_tokens')->sole())->toBe($before);
})->group('integration', 'redis', 'worker');
