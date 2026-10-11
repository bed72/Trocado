<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Adapters;

use App\Core\Application\Ports\ObservabilityPort;
use App\Identity\Application\Ports\EmailVerificationPort;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Illuminate\Auth\Events\Registered;
use Illuminate\Auth\Events\Verified;
use Illuminate\Support\Facades\Event;
use Throwable;

final class EmailVerificationAdapter implements EmailVerificationPort
{
    public function __construct(private readonly ObservabilityPort $port) {}

    public function requestForRegistration(int $userId): void
    {
        $user = UserModel::query()->find(id: $userId);

        if ($user !== null && ! $user->hasVerifiedEmail()) {
            try {
                Event::dispatch(new Registered(user: $user));
            } catch (Throwable $exception) {
                $this->reportFailure(exception: $exception, userId: $userId);
            }
        }
    }

    public function requestForEmail(string $email): void
    {
        $user = UserModel::query()->where(column: 'email', operator: '=', value: $email)->first();

        if ($user !== null && ! $user->hasVerifiedEmail()) {
            $this->notify(user: $user);
        }
    }

    public function publishVerified(int $userId): void
    {
        $user = UserModel::query()->find(id: $userId);

        if ($user !== null && $user->hasVerifiedEmail()) {
            Event::dispatch(new Verified(user: $user));
        }
    }

    private function notify(UserModel $user): void
    {
        try {
            $user->sendEmailVerificationNotification();
        } catch (Throwable $exception) {
            $this->reportFailure(exception: $exception, userId: (int) $user->getKey());
        }
    }

    private function reportFailure(Throwable $exception, int $userId): void
    {
        $this->port->emit('email.verification_queue_failed', [
            'user_id' => $userId,
            'exception_class' => $exception::class,
        ]);
    }
}
