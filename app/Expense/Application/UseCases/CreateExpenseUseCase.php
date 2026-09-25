<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\TransactionPort;
use App\Expense\Application\Data\CreateExpenseInput;
use App\Expense\Application\Ports\ExpenseClassificationDispatchPort;
use App\Expense\Application\Ports\UserPort;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;
use DateTimeImmutable;
use Throwable;

final readonly class CreateExpenseUseCase
{
    public function __construct(
        private UserPort $userPort,
        private TransactionPort $transactionPort,
        private ObservabilityPort $observabilityPort,
        private ExpenseClassificationDispatchPort $dispatchPort,
        private ExpenseRepository $repository,
    ) {}

    public function execute(CreateExpenseInput $input): ExpenseEntity
    {
        return $this->transactionPort->execute(function () use ($input): ExpenseEntity {
            $expense = $this->repository->create(expense: new ExpenseEntity(
                id: null,
                amount: $input->amount,
                category: $input->category,
                userId: $this->userPort->id(),
                occurredOn: $input->occurredOn,
                description: $input->description,
            ));

            $this->transactionPort->afterCommit(function () use ($expense): void {
                $this->observabilityPort->emit('expense.created', [
                    'expense_id' => $expense->id,
                    'user_id' => $expense->userId,
                ]);
            });

            if ($input->category !== null || ! ExpenseEntity::isDescriptionEligibleForClassification($input->description)) {
                return $expense;
            }

            $token = bin2hex(random_bytes(16));

            if (! $this->repository->beginClassificationAttempt(
                expenseId: (int) $expense->id,
                token: $token,
                expiresAt: new DateTimeImmutable('+5 minutes'),
            )) {
                return $expense;
            }

            try {
                $this->dispatchPort->dispatch(expenseId: (int) $expense->id, token: $token);
            } catch (Throwable) {
                $this->repository->cancelClassification(expenseId: (int) $expense->id, token: $token);
            }

            return $expense;
        });
    }
}
