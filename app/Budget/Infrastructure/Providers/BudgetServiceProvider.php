<?php

declare(strict_types=1);

namespace App\Budget\Infrastructure\Providers;

use App\Budget\Application\Ports\BudgetWritePort;
use App\Budget\Application\Repositories\BudgetRecurrenceRepository;
use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Infrastructure\Adapters\BudgetWriteAdapter;
use App\Budget\Infrastructure\Console\Commands\ProcessDueBudgetRecurrencesCommand;
use App\Budget\Infrastructure\Persistence\Repositories\EloquentBudgetRecurrenceRepository;
use App\Budget\Infrastructure\Persistence\Repositories\EloquentBudgetRepository;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\ServiceProvider;

final class BudgetServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: BudgetWritePort::class, concrete: BudgetWriteAdapter::class);
        $this->app->bind(abstract: BudgetRepository::class, concrete: EloquentBudgetRepository::class);
        $this->app->bind(abstract: BudgetRecurrenceRepository::class, concrete: EloquentBudgetRecurrenceRepository::class);
    }

    public function boot(): void
    {
        Model::preventLazyLoading(! $this->app->isProduction());
        $this->commands(commands: [ProcessDueBudgetRecurrencesCommand::class]);
    }
}
