<?php

declare(strict_types=1);

namespace App\Budget\Application\UseCases;

use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Domain\Entities\BudgetEntity;

final readonly class ListBudgetsUseCase
{
    public function __construct(private BudgetRepository $budgets) {}

    /** @return list<BudgetEntity> */
    public function execute(): array
    {
        return $this->budgets->all();
    }
}
