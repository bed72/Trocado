<?php

declare(strict_types=1);

namespace App\Expense\Application\Repositories;

use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Data\GetAllExpenseInput;
use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Domain\Entities\ExpenseEntity;

interface ExpenseRepository
{
    public function delete(string $id, string $userId): bool;

    public function create(ExpenseEntity $expense): ExpenseEntity;

    public function getById(string $id, string $userId): ?ExpenseEntity;

    public function getAll(string $userId, GetAllExpenseInput $input): ExpensePageOutput;

    public function update(string $id, string $userId, UpdateExpenseInput $input): ?ExpenseEntity;
}
