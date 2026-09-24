<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Core\Application\Ports\ScopePort;
use App\Expense\Application\Data\CreateExpenseInput;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;

final class CreateExpenseUseCase
{
    public function __construct(
        private readonly ScopePort $port,
        private readonly ExpenseRepository $repository,
    ) {}

    public function execute(CreateExpenseInput $input): ExpenseEntity
    {
        return $this->port->execute($input->userId, fn (): ExpenseEntity => $this->repository->create(expense: new ExpenseEntity(
            id: null,
            userId: $input->userId,
            amount: $input->amount,
            category: $input->category,
            occurredOn: $input->occurredOn,
            description: $input->description,
        )));
    }
}
