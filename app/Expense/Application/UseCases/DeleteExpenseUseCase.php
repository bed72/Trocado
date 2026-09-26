<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\TransactionPort;
use App\Expense\Application\Exceptions\ExpenseNotFoundException;
use App\Expense\Application\Ports\UserPort;
use App\Expense\Application\Repositories\ExpenseRepository;

final readonly class DeleteExpenseUseCase
{
    public function __construct(
        private UserPort $userPort,
        private ExpenseRepository $repository,
        private TransactionPort $transactionPort,
        private ObservabilityPort $observabilityPort,
    ) {}

    public function execute(int $id): void
    {
        $userId = $this->userPort->id();

        if (! $this->repository->deleteByUser(id: $id, userId: $userId)) {
            throw new ExpenseNotFoundException;
        }

        $this->transactionPort->afterCommit(fn () => $this->observabilityPort->emit('expense.deleted', [
            'expense_id' => $id,
            'user_id' => $userId,
        ]));
    }
}
