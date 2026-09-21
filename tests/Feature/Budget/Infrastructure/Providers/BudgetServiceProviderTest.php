<?php

declare(strict_types=1);

use App\Budget\Application\Ports\BudgetWritePort;
use App\Budget\Application\Repositories\BudgetRecurrenceRepository;
use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Infrastructure\Adapters\BudgetWriteAdapter;
use App\Budget\Infrastructure\Persistence\Repositories\EloquentBudgetRecurrenceRepository;
use App\Budget\Infrastructure\Persistence\Repositories\EloquentBudgetRepository;

it('binds the budget repository contract to the Eloquent implementation', function (): void {
    expect(app(BudgetRepository::class))->toBeInstanceOf(EloquentBudgetRepository::class)
        ->and(app(BudgetRecurrenceRepository::class))->toBeInstanceOf(EloquentBudgetRecurrenceRepository::class)
        ->and(app(BudgetWritePort::class))->toBeInstanceOf(BudgetWriteAdapter::class);
});
