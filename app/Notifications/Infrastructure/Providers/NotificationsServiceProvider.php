<?php

declare(strict_types=1);

namespace App\Notifications\Infrastructure\Providers;

use App\Notifications\Application\Repositories\NotificationRegistrationRepository;
use App\Notifications\Infrastructure\Repositories\Persistence\EloquentNotificationRepository;
use Illuminate\Support\ServiceProvider;

final class NotificationsServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(NotificationRegistrationRepository::class, EloquentNotificationRepository::class);
    }
}
