<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Providers;

use App\Expense\Application\Ports\ExpenseListCachePort;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Infrastructure\Adapters\Cache\ExpenseListCacheAdapter;
use App\Expense\Infrastructure\Repositories\Persistence\EloquentExpenseRepository;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\ServiceProvider;

final class ExpenseServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: ExpenseRepository::class, concrete: EloquentExpenseRepository::class);
        $this->app->bind(abstract: ExpenseListCachePort::class, concrete: ExpenseListCacheAdapter::class);
    }

    public function boot(): void
    {
        Model::preventLazyLoading(! $this->app->environment('production'));
    }
}
