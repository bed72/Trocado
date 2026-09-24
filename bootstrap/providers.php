<?php

use App\Expense\Infrastructure\Providers\ExpenseServiceProvider;
use App\Identity\Infrastructure\Providers\IdentityServiceProvider;

return [
    ExpenseServiceProvider::class,
    IdentityServiceProvider::class,
];
