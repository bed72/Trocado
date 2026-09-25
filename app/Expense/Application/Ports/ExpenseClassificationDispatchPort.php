<?php

declare(strict_types=1);

namespace App\Expense\Application\Ports;

interface ExpenseClassificationDispatchPort
{
    public function dispatch(string $token, int $expenseId): void;
}
