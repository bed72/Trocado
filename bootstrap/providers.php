<?php

use App\Authentication\Infrastructure\Providers\AuthenticationServiceProvider;
use App\Budget\Infrastructure\Providers\BudgetServiceProvider;
use App\User\Infrastructure\Providers\UserServiceProvider;

return [
    UserServiceProvider::class,
    BudgetServiceProvider::class,
    AuthenticationServiceProvider::class,
];
