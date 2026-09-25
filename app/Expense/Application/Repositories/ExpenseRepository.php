<?php

declare(strict_types=1);

namespace App\Expense\Application\Repositories;

use App\Expense\Application\Data\ExpenseClassificationOutput;
use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Domain\Entities\ExpenseEntity;
use App\Expense\Domain\Enums\ExpenseCategoryEnum;
use DateTimeImmutable;

interface ExpenseRepository
{
    public function deleteByUser(int $id, int $userId): bool;

    public function create(ExpenseEntity $expense): ExpenseEntity;

    public function cancelClassification(int $expenseId, string $token): void;

    public function listByUser(int $userId, int $size, ?string $cursor): ExpensePageOutput;

    public function updateByUser(int $id, int $userId, UpdateExpenseInput $input): ?ExpenseEntity;

    public function beginClassificationAttempt(int $expenseId, string $token, DateTimeImmutable $expiresAt): bool;

    public function findClassificationAttempt(int $expenseId, string $token): ?ExpenseClassificationOutput;

    public function applyClassificationAttempt(int $expenseId, string $token, string $description, ExpenseCategoryEnum $category): ?int;
}
