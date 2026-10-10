<?php

declare(strict_types=1);

namespace App\Metrics\Application\Data;

final readonly class ExpenseCategoryTotalOutput
{
    public function __construct(
        public string $category,
        public string $totalAmount,
    ) {}
}
