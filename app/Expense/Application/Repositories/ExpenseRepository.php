<?php

declare(strict_types=1);

namespace App\Expense\Application\Repositories;

use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Domain\Entities\ExpenseEntity;

interface ExpenseRepository
{
    public function deleteByUser(int $id, int $userId): bool;

    public function create(ExpenseEntity $expense): ExpenseEntity;

    public function listByUser(int $userId, int $size, ?string $cursor): ExpensePageOutput;

    public function updateByUser(int $id, int $userId, UpdateExpenseInput $input): ?ExpenseEntity;
}
