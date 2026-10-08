<?php

declare(strict_types=1);

namespace App\Expense\Application\Repositories;

use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Domain\Entities\ExpenseEntity;

interface ExpenseRepository
{
    public function delete(int $id, int $userId): bool;

    public function create(ExpenseEntity $expense): ExpenseEntity;

    public function getById(int $id, int $userId): ?ExpenseEntity;

    public function getAll(int $userId, int $size, ?string $cursor): ExpensePageOutput;

    public function update(int $id, int $userId, UpdateExpenseInput $input): ?ExpenseEntity;
}
