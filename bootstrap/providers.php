<?php

use App\Budget\Infrastructure\Providers\BudgetServiceProvider;
use App\User\Infrastructure\Providers\UserServiceProvider;

return [
    BudgetServiceProvider::class,
    UserServiceProvider::class,
];
