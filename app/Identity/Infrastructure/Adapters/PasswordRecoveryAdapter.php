<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Adapters;

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Domain\ValueObjects\UuidValueObject;
use App\Identity\Application\Ports\PasswordRecoveryPort;
use App\Identity\Infrastructure\Notifications\PasswordRecoveryNotification;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Illuminate\Contracts\Notifications\Dispatcher;
use SensitiveParameter;
use Throwable;

final readonly class PasswordRecoveryAdapter implements PasswordRecoveryPort
{
    public function __construct(
        private ObservabilityPort $port,
        private Dispatcher $notifications,
        private PasswordRecoveryUrlAdapter $urlAdapter,
        private PasswordRecoveryMailChannelAdapter $mailAdapter,
    ) {}

    public function isAvailable(): bool
    {
        try {
            $this->urlAdapter->baseUrl();
            $this->mailAdapter->assertAvailable();

            return true;
        } catch (Throwable $exception) {
            $this->port->emit('identity.password_recovery_unavailable', ['exception_class' => $exception::class]);

            return false;
        }
    }

    public function requestLink(string $userId, string $email, #[SensitiveParameter] string $token): void
    {
        try {
            $userId = UuidValueObject::fromString($userId)->value();
            $user = UserModel::query()->find($userId);

            if ($user === null || $user->email !== $email) {
                return;
            }

            $url = $this->urlAdapter->forToken($email, $token);
            $this->mailAdapter->assertAvailable();
            $this->notifications->send($user, new PasswordRecoveryNotification(expectedEmail: $email, url: $url));
        } catch (Throwable $exception) {
            $this->port->emit('identity.password_recovery_queue_failed', ['exception_class' => $exception::class]);
        }
    }
}
