<?php

declare(strict_types=1);

namespace App\Insights\Application\Data;

final readonly class ExpenseAnalysisOutput
{
    public function __construct(
        public bool $hasHistoricalExpenses,
        public ExpensePeriodAnalysisOutput $twoMonthsAgo,
        public ExpensePeriodAnalysisOutput $currentMonth,
        public ExpensePeriodAnalysisOutput $previousMonth,
        public ?ExpensePeriodAnalysisOutput $currentComparison,
        public ?ExpensePeriodAnalysisOutput $previousComparison,
    ) {}
}
