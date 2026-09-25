<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Expense\Application\Data\CreateExpenseInput;
use App\Expense\Application\Ports\UserPort;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;

final class CreateExpenseUseCase
{
    public function __construct(private readonly UserPort $port, private readonly ExpenseRepository $repository) {}

    public function execute(CreateExpenseInput $input): ExpenseEntity
    {
        return $this->repository->create(expense: new ExpenseEntity(
            id: null,
            amount: $input->amount,
            userId: $this->port->id(),
            category: $input->category,
            occurredOn: $input->occurredOn,
            description: $input->description,
        ));
    }
}
