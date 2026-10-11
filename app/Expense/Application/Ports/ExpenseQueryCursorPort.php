<?php

declare(strict_types=1);

namespace App\Expense\Application\Ports;

use App\Expense\Application\Data\ExpenseCursorOutput;
use App\Expense\Application\Data\GetAllExpenseInput;

interface ExpenseQueryCursorPort
{
    public function fingerprint(GetAllExpenseInput $input): string;

    public function decode(GetAllExpenseInput $input): ?ExpenseCursorOutput;

    public function encode(GetAllExpenseInput $input, ExpenseCursorOutput $cursor): string;
}
