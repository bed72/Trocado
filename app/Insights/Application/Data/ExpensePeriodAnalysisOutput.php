<?php

declare(strict_types=1);

namespace App\Insights\Application\Data;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;

final readonly class ExpensePeriodAnalysisOutput
{
    /**
     * Amounts are exact integers in minor units, including sums beyond PHP_INT_MAX.
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
        public DatePeriodValueObject $period,
    ) {}
}
