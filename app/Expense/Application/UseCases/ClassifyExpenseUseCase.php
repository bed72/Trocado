<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Expense\Application\Ports\ExpenseClassificationPort;
use App\Expense\Application\Repositories\ExpenseRepository;

final readonly class ClassifyExpenseUseCase
{
    public function __construct(private ExpenseClassificationPort $port, private ExpenseRepository $repository) {}

    public function execute(int $expenseId, string $token): void
    {
        $attempt = $this->repository->findClassificationAttempt(expenseId: $expenseId, token: $token);

        if ($attempt === null) {
            return;
        }

        $category = $this->port->suggest(description: $attempt->description);

        if ($category === null) {
            $this->repository->cancelClassificationAttempt(expenseId: $expenseId, token: $token);

            return;
        }

        $this->repository->applyClassificationAttempt(
            token: $token,
            category: $category,
            expenseId: $expenseId,
            description: $attempt->description,
        );
    }

    public function fail(int $expenseId, string $token): void
    {
        $this->repository->cancelClassificationAttempt(expenseId: $expenseId, token: $token);
    }
}
