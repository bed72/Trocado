<?php

declare(strict_types=1);

namespace App\Expense\Application\Repositories;

use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Domain\Entities\ExpenseEntity;

interface ExpenseRepository
{
    public function create(ExpenseEntity $expense): ExpenseEntity;

    public function deleteByUser(int $id, int $userId): bool;

    public function listByUser(int $userId, int $size, ?string $cursor): ExpensePageOutput;
}
