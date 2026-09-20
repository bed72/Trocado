<?php

declare(strict_types=1);

namespace App\Budget\Infrastructure\Providers;

use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Infrastructure\Persistence\Repositories\EloquentBudgetRepository;
use Illuminate\Support\ServiceProvider;

final class BudgetServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: BudgetRepository::class, concrete: EloquentBudgetRepository::class);
    }
}
