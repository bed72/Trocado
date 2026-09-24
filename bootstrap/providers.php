<?php

use App\Core\Infrastructure\Providers\AuthenticatedRateLimitServiceProvider;
use App\Core\Infrastructure\Providers\ScopeServiceProvider;
use App\Core\Infrastructure\Providers\TransactionServiceProvider;
use App\Expense\Infrastructure\Providers\ExpenseServiceProvider;
use App\Identity\Infrastructure\Providers\IdentityServiceProvider;

return [
    ScopeServiceProvider::class,
    ExpenseServiceProvider::class,
    IdentityServiceProvider::class,
    TransactionServiceProvider::class,
    AuthenticatedRateLimitServiceProvider::class,
];
