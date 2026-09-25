<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Providers;

use App\Core\Application\Ports\TransactionPort;
use App\Core\Infrastructure\Adapters\TransactionAdapter;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

final class CoreServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: TransactionPort::class, concrete: TransactionAdapter::class);
    }

    public function boot(): void
    {
        RateLimiter::for('api.authenticated', fn (Request $request): Limit => Limit::perMinute(60)
            ->by('api:authenticated:user:'.$request->user()->getAuthIdentifier()));
    }
}
