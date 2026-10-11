<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Core\Application\Ports\UserPort;
use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Data\GetAllExpenseInput;
use App\Expense\Application\Ports\ExpenseQueryCursorPort;
use App\Expense\Application\Repositories\ExpenseRepository;

final readonly class GetAllExpenseUseCase
{
    public function __construct(private UserPort $userPort, private ExpenseQueryCursorPort $cursorPort, private ExpenseRepository $repository) {}

    public function execute(GetAllExpenseInput $input): ExpensePageOutput
    {
        $this->cursorPort->decode($input);

        return $this->repository->getAll(userId: $this->userPort->id(), input: $input);
    }
}
