<?php

declare(strict_types=1);

namespace App\Authentication\Infrastructure\Providers;

use App\Authentication\Application\Ports\AuthenticationWritePort;
use App\Authentication\Application\Ports\SignInPort;
use App\Authentication\Application\Ports\SignOutPort;
use App\Authentication\Application\Ports\SignUpPort;
use App\Authentication\Infrastructure\Adapters\AuthenticationWriteAdapter;
use App\Authentication\Infrastructure\Adapters\SignInAdapter;
use App\Authentication\Infrastructure\Adapters\SignOutAdapter;
use App\Authentication\Infrastructure\Adapters\SignUpAdapter;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\ServiceProvider;

final class AuthenticationServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: SignUpPort::class, concrete: SignUpAdapter::class);
        $this->app->bind(abstract: SignInPort::class, concrete: SignInAdapter::class);
        $this->app->bind(abstract: SignOutPort::class, concrete: SignOutAdapter::class);
        $this->app->bind(abstract: AuthenticationWritePort::class, concrete: AuthenticationWriteAdapter::class);
    }

    public function boot(): void
    {
        Model::preventLazyLoading(! $this->app->isProduction());
    }
}
