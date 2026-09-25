<?php

declare(strict_types=1);

namespace App\Expense\Application\Data;

use App\Expense\Domain\Enums\ExpenseCategoryEnum;

final readonly class ApplyExpenseClassificationInput
{
    public function __construct(
        public int $expenseId,
        public string $token,
        public string $description,
        public ExpenseCategoryEnum $category,
    ) {}
}
