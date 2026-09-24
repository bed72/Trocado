<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Providers;

use App\Core\Application\Ports\ScopePort;
use App\Core\Infrastructure\Adapters\ScopeAdapter;
use Illuminate\Support\ServiceProvider;

final class ScopeServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: ScopePort::class, concrete: ScopeAdapter::class);
    }
}
