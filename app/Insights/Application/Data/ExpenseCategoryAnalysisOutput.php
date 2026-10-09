<?php

declare(strict_types=1);

namespace App\Insights\Application\Data;

final readonly class ExpenseCategoryAnalysisOutput
{
    /** Amounts are exact integer cents, including sums beyond PHP_INT_MAX. */
    public function __construct(
        public string $category,
        public string $totalAmount,
    ) {}
}
