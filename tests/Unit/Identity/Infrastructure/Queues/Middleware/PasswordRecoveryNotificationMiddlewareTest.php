<?php

declare(strict_types=1);

use App\Identity\Infrastructure\Queues\Middleware\PasswordRecoveryNotificationMiddleware;
use Tests\Support\Core\Spies\ObservabilityPortSpy;

it('allows successful processing without extra telemetry', function (): void {
    $port = new ObservabilityPortSpy;
    $job = new stdClass;
    $result = (new PasswordRecoveryNotificationMiddleware($port))->handle($job, function (object $value) use ($job): string {
        expect($value)->toBe($job);

        return 'processed';
    });
    expect($result)->toBe('processed')->and($port->events)->toBe([]);
});

it('throws a retryable generic failure without the original message previous or sensitive trace arguments', function (): void {
    $port = new ObservabilityPortSpy;
    $secret = 'sensitive-recovery-url-and-token';
    try {
        (new PasswordRecoveryNotificationMiddleware($port))->handle((object) ['secret' => $secret], static function () use ($secret): never {
            throw new RuntimeException($secret, previous: new RuntimeException($secret));
        });
        $this->fail('Processing must fail for the worker to retry.');
    } catch (RuntimeException $exception) {
        expect($exception->getMessage())->toBe('Não foi possível entregar a notificação de recuperação de senha.')
            ->and($exception->getPrevious())->toBeNull()
            ->and((string) $exception)->not->toContain($secret);
    }
    expect($port->events)->toBe([['event' => 'identity.password_recovery_delivery_failed', 'attributes' => ['exception_class' => RuntimeException::class]]]);
});
