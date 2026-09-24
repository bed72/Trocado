<?php

use App\Budget\Infrastructure\Providers\BudgetServiceProvider;
use App\Expense\Infrastructure\Providers\ExpenseServiceProvider;
use App\Identity\Infrastructure\Providers\IdentityServiceProvider;

return [
    BudgetServiceProvider::class,
    ExpenseServiceProvider::class,
    IdentityServiceProvider::class,
];
