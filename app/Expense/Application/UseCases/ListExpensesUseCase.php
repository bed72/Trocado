<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Core\Application\Ports\ScopePort;
use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Repositories\ExpenseRepository;

final readonly class ListExpensesUseCase
{
    public function __construct(private ScopePort $port, private ExpenseRepository $repository) {}

    public function execute(int $userId, int $size, ?string $cursor): ExpensePageOutput
    {
        return $this->port->execute($userId, fn (): ExpensePageOutput => $this->repository->listByUser(userId: $userId, size: $size, cursor: $cursor));
    }
}
