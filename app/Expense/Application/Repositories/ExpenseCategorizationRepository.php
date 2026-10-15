<?php

declare(strict_types=1);

namespace App\Expense\Application\Repositories;

use App\Expense\Application\Data\ApplyExpenseClassificationInput;
use App\Expense\Application\Data\ExpenseClassificationOutput;
use DateTimeImmutable;

interface ExpenseCategorizationRepository
{
    public function cancelClassification(string $expenseId, string $token): void;

    public function applyClassificationAttempt(ApplyExpenseClassificationInput $input): ?string;

    public function findClassificationAttempt(string $expenseId, string $token): ?ExpenseClassificationOutput;

    public function beginClassificationAttempt(string $expenseId, string $token, DateTimeImmutable $expiresAt): bool;
}
