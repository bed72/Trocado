<?php

use App\Core\Infrastructure\Providers\CoreServiceProvider;
use App\Expense\Infrastructure\Providers\ExpenseServiceProvider;
use App\Identity\Infrastructure\Providers\IdentityServiceProvider;
use App\Insights\Infrastructure\Providers\InsightsServiceProvider;
use App\Metrics\Infrastructure\Providers\MetricsServiceProvider;
use App\Notifications\Infrastructure\Providers\NotificationsServiceProvider;

return [
    CoreServiceProvider::class,
    ExpenseServiceProvider::class,
    IdentityServiceProvider::class,
    InsightsServiceProvider::class,
    MetricsServiceProvider::class,
    NotificationsServiceProvider::class,
];
