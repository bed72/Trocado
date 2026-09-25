<?php

declare(strict_types=1);

namespace App\Expense\Application\Ports;

use App\Expense\Domain\Enums\ExpenseCategoryEnum;

interface ExpenseClassificationPort
{
    public function suggest(string $description): ?ExpenseCategoryEnum;
}
