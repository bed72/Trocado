<?php

declare(strict_types=1);

namespace App\Insights\Infrastructure\Providers;

use App\Insights\Application\Repositories\ExpenseAnalysisRepository;
use App\Insights\Infrastructure\Repositories\Persistence\EloquentExpenseAnalysisRepository;
use Illuminate\Support\ServiceProvider;

final class InsightsServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: ExpenseAnalysisRepository::class, concrete: EloquentExpenseAnalysisRepository::class);
    }
}
