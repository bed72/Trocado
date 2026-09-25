<?php

declare(strict_types=1);

namespace App\Expense\Application\Data;

final readonly class ExpenseClassificationOutput
{
    public function __construct(public string $description) {}
}
