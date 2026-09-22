<?php

use App\Budget\Infrastructure\Providers\BudgetServiceProvider;
use App\Identity\Infrastructure\Providers\IdentityServiceProvider;

return [
    IdentityServiceProvider::class,
    BudgetServiceProvider::class,
];
