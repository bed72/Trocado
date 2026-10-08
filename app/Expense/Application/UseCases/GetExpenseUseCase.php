<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Expense\Application\Exceptions\ExpenseNotFoundException;
use App\Expense\Application\Ports\UserPort;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;

final readonly class GetExpenseUseCase
{
    public function __construct(private UserPort $port, private ExpenseRepository $repository) {}

    public function execute(int $id): ExpenseEntity
    {
        return $this->repository->getById(id: $id, userId: $this->port->id())
            ?? throw new ExpenseNotFoundException;
    }
}
