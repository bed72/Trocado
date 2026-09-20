<?php

declare(strict_types=1);

use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Infrastructure\Persistence\Repositories\EloquentBudgetRepository;

it('binds the budget repository contract to the Eloquent implementation', function (): void {
    expect(app(BudgetRepository::class))->toBeInstanceOf(EloquentBudgetRepository::class);
});
