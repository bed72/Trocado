<?php

declare(strict_types=1);

namespace App\Insights\Application\Data;

use App\Insights\Domain\ValueObjects\InsightPeriodValueObject;

final readonly class ExpensePeriodAnalysisOutput
{
    /**
     * Amounts are exact integer cents, including sums beyond PHP_INT_MAX.
     *
     * @param  list<ExpenseCategoryAnalysisOutput>  $categories
     */
    public function __construct(
        public int $expenseCount,
        public array $categories,
        public string $totalAmount,
        public int $distinctDateCount,
        public string $largestExpenseAmount,
        public ?string $largestExpenseCategory,
        public InsightPeriodValueObject $period,
    ) {}
}
