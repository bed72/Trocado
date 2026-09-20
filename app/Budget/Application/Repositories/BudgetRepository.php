<?php

declare(strict_types=1);

namespace App\Budget\Application\Repositories;

use App\Budget\Domain\Entities\BudgetEntity;

interface BudgetRepository
{
    /** @return list<BudgetEntity> */
    public function all(): array;
    public function delete(int $id): bool;
    public function findById(int $id): ?BudgetEntity;
    public function save(BudgetEntity $budget): BudgetEntity;
}
