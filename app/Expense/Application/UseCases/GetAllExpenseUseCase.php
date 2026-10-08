<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Ports\UserPort;
use App\Expense\Application\Repositories\ExpenseRepository;

final readonly class GetAllExpenseUseCase
{
    public function __construct(private UserPort $port, private ExpenseRepository $repository) {}

    public function execute(int $size, ?string $cursor): ExpensePageOutput
    {
        return $this->repository->getAll(userId: $this->port->id(), size: $size, cursor: $cursor);
    }
}
