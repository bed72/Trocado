<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Core\Application\Ports\ScopePort;
use App\Expense\Application\Data\CreateExpenseInput;
use App\Expense\Application\Ports\ExpenseListCachePort;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;

final class CreateExpenseUseCase
{
    public function __construct(
        private readonly ScopePort $scopePort,
        private readonly ExpenseRepository $repository,
        private readonly ExpenseListCachePort $cachePort,
    ) {}

    public function execute(CreateExpenseInput $input): ExpenseEntity
    {
        $expense = $this->scopePort->execute($input->userId, fn (): ExpenseEntity => $this->repository->create(expense: new ExpenseEntity(
            id: null,
            userId: $input->userId,
            amount: $input->amount,
            category: $input->category,
            occurredOn: $input->occurredOn,
            description: $input->description,
        )));

        $this->cachePort->invalidate($input->userId);

        return $expense;
    }
}
