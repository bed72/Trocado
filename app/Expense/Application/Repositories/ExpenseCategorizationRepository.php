<?php

declare(strict_types=1);

namespace App\Expense\Application\Repositories;

use App\Expense\Application\Data\ApplyExpenseClassificationInput;
use App\Expense\Application\Data\ExpenseClassificationOutput;
use DateTimeImmutable;

interface ExpenseCategorizationRepository
{
    public function cancelClassification(int $expenseId, string $token): void;

    public function applyClassificationAttempt(ApplyExpenseClassificationInput $input): ?int;

    public function findClassificationAttempt(int $expenseId, string $token): ?ExpenseClassificationOutput;

    public function beginClassificationAttempt(int $expenseId, string $token, DateTimeImmutable $expiresAt): bool;
}
