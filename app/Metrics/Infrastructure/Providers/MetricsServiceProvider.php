<?php

declare(strict_types=1);

namespace App\Metrics\Infrastructure\Providers;

use App\Metrics\Application\Ports\ExpenseMetricsPort;
use App\Metrics\Infrastructure\Adapters\ExpenseMetricsAdapter;
use Illuminate\Support\ServiceProvider;

final class MetricsServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: ExpenseMetricsPort::class, concrete: ExpenseMetricsAdapter::class);
    }
}
