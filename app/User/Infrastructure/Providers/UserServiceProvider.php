<?php

declare(strict_types=1);

namespace App\User\Infrastructure\Providers;

use App\User\Application\Repositories\UserRepository;
use App\User\Infrastructure\Persistence\Repositories\EloquentUserRepository;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\ServiceProvider;

final class UserServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: UserRepository::class, concrete: EloquentUserRepository::class);
    }

    public function boot(): void
    {
        Model::preventLazyLoading(! $this->app->isProduction());
    }
}
