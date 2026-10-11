<?php

declare(strict_types=1);

namespace App\Metrics\Infrastructure\Providers;

use App\Metrics\Application\Repositories\ExpenseMetricsRepository;
use App\Metrics\Infrastructure\Repositories\Persistence\EloquentExpenseMetricsRepository;
use Illuminate\Support\ServiceProvider;

final class MetricsServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: ExpenseMetricsRepository::class, concrete: EloquentExpenseMetricsRepository::class);
    }
}
