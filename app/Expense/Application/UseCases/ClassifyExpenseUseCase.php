<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Expense\Application\Data\ApplyExpenseClassificationInput;
use App\Expense\Application\Ports\ExpenseClassificationPort;
use App\Expense\Application\Repositories\ExpenseCategorizationRepository;

final readonly class ClassifyExpenseUseCase
{
    public function __construct(private ExpenseClassificationPort $port, private ExpenseCategorizationRepository $repository) {}

    public function execute(int $expenseId, string $token): void
    {
        $attempt = $this->repository->findClassificationAttempt(expenseId: $expenseId, token: $token);

        if ($attempt === null) {
            return;
        }

        $category = $this->port->suggest(description: $attempt->description);

        if ($category === null) {
            $this->repository->cancelClassification(expenseId: $expenseId, token: $token);

            return;
        }

        $this->repository->applyClassificationAttempt(input: new ApplyExpenseClassificationInput(
            expenseId: $expenseId,
            token: $token,
            description: $attempt->description,
            category: $category,
        ));
    }

    public function fail(int $expenseId, string $token): void
    {
        $this->repository->cancelClassification(expenseId: $expenseId, token: $token);
    }
}
