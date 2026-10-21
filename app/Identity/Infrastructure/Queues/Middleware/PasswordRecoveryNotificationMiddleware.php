<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Queues\Middleware;

use App\Core\Application\Ports\ObservabilityPort;
use RuntimeException;
use SensitiveParameter;
use Throwable;

final readonly class PasswordRecoveryNotificationMiddleware
{
    public function __construct(private ObservabilityPort $port) {}

    public function handle(#[SensitiveParameter] object $job, #[SensitiveParameter] callable $next): mixed
    {
        try {
            return $next($job);
        } catch (Throwable $exception) {
            $this->port->emit('identity.password_recovery_delivery_failed', ['exception_class' => $exception::class]);

            throw new RuntimeException('Não foi possível entregar a notificação de recuperação de senha.');
        }
    }
}
