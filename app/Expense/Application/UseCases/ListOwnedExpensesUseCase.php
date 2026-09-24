<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Repositories\ExpenseRepository;

final readonly class ListOwnedExpensesUseCase
{
    public function __construct(private ExpenseRepository $repository) {}

    public function execute(int $userId, int $size, ?string $cursor): ExpensePageOutput
    {
        return $this->repository->listByUser(userId: $userId, size: $size, cursor: $cursor);
    }
}
