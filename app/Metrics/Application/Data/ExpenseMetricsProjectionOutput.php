<?php

declare(strict_types=1);

namespace App\Metrics\Application\Data;

final readonly class ExpenseMetricsProjectionOutput
{
    /** @param list<ExpenseCategoryTotalOutput> $categories */
    public function __construct(
        public string $totalCents,
        public array $categories = [],
    ) {}
}
