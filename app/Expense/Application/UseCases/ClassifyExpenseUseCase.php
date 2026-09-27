<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\TransactionPort;
use App\Expense\Application\Data\ApplyExpenseClassificationInput;
use App\Expense\Application\Ports\ExpenseClassificationPort;
use App\Expense\Application\Repositories\ExpenseCategorizationRepository;

final readonly class ClassifyExpenseUseCase
{
    public function __construct(
        private TransactionPort $transactionPort,
        private ObservabilityPort $observabilityPort,
        private ExpenseClassificationPort $classificationPort,
        private ExpenseCategorizationRepository $repository,
    ) {}

    public function execute(int $expenseId, string $token): void
    {
        $attempt = $this->repository->findClassificationAttempt(expenseId: $expenseId, token: $token);

        if ($attempt === null) {
            return;
        }

        $category = $this->classificationPort->suggest(description: $attempt->description);

        if ($category === null) {
            $this->repository->cancelClassification(expenseId: $expenseId, token: $token);

            return;
        }

        $userId = $this->repository->applyClassificationAttempt(input: new ApplyExpenseClassificationInput(
            token: $token,
            category: $category,
            expenseId: $expenseId,
            description: $attempt->description,
        ));

        if ($userId !== null) {
            $this->transactionPort->afterCommit(fn () => $this->observabilityPort->emit('expense.classified', [
                'user_id' => $userId,
                'expense_id' => $expenseId,
                'category' => $category->value,
            ]));
        }
    }

    public function fail(int $expenseId, string $token): void
    {
        $this->repository->cancelClassification(expenseId: $expenseId, token: $token);
    }
}
