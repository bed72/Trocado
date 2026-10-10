<?php

use App\Core\Infrastructure\Providers\CoreServiceProvider;
use App\Expense\Infrastructure\Providers\ExpenseServiceProvider;
use App\Identity\Infrastructure\Providers\IdentityServiceProvider;
use App\Insights\Infrastructure\Providers\InsightsServiceProvider;
use App\Metrics\Infrastructure\Providers\MetricsServiceProvider;

return [
    CoreServiceProvider::class,
    ExpenseServiceProvider::class,
    IdentityServiceProvider::class,
    InsightsServiceProvider::class,
    MetricsServiceProvider::class,
];
