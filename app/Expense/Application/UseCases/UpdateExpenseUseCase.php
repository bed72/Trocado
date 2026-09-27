<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\TransactionPort;
use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Application\Exceptions\ExpenseNotFoundException;
use App\Expense\Application\Ports\UserPort;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;

final readonly class UpdateExpenseUseCase
{
    public function __construct(
        private UserPort $userPort,
        private TransactionPort $transactionPort,
        private ObservabilityPort $observabilityPort,
        private ExpenseRepository $repository,
    ) {}

    public function execute(int $id, UpdateExpenseInput $input): ExpenseEntity
    {
        $updated = $this->repository->updateByUser(id: $id, userId: $this->userPort->id(), input: $input)
            ?? throw new ExpenseNotFoundException;

        $this->transactionPort->afterCommit(fn () => $this->observabilityPort->emit('expense.updated', [
            'expense_id' => $updated->id,
            'user_id' => $updated->userId,
        ]));

        return $updated;
    }
}
