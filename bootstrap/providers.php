<?php

use App\Core\Infrastructure\Providers\CoreServiceProvider;
use App\Expense\Infrastructure\Providers\ExpenseServiceProvider;
use App\Identity\Infrastructure\Providers\IdentityServiceProvider;

return [
    CoreServiceProvider::class,
    ExpenseServiceProvider::class,
    IdentityServiceProvider::class,
];
