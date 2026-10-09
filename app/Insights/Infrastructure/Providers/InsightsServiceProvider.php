<?php

declare(strict_types=1);

namespace App\Insights\Infrastructure\Providers;

use App\Insights\Application\Ports\ExpenseAnalysisPort;
use App\Insights\Infrastructure\Adapters\ExpenseAnalysisAdapter;
use Illuminate\Support\ServiceProvider;

final class InsightsServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: ExpenseAnalysisPort::class, concrete: ExpenseAnalysisAdapter::class);
    }
}
