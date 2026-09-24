<?php

declare(strict_types=1);

namespace App\Expense\Application\Repositories;

use App\Expense\Domain\Entities\ExpenseEntity;

interface ExpenseRepository
{
    public function create(ExpenseEntity $expense): ExpenseEntity;
}
