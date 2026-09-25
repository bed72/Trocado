<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Application\Exceptions\ExpenseNotFoundException;
use App\Expense\Application\Ports\UserPort;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;

final readonly class UpdateExpenseUseCase
{
    public function __construct(private UserPort $port, private ExpenseRepository $repository) {}

    public function execute(int $id, UpdateExpenseInput $input): ExpenseEntity
    {
        return $this->repository->updateByUser(id: $id, userId: $this->port->id(), input: $input)
            ?? throw new ExpenseNotFoundException;
    }
}
