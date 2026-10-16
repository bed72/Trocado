<?php

declare(strict_types=1);

namespace App\Insights\Infrastructure\Repositories\Persistence;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Application\Data\ExpenseAnalysisOutput;
use App\Insights\Application\Data\ExpenseCategoryAnalysisOutput;
use App\Insights\Application\Data\ExpensePeriodAnalysisOutput;
use App\Insights\Application\Repositories\ExpenseAnalysisRepository;
use App\Insights\Domain\Enums\InsightPeriodModeEnum;
use App\Insights\Domain\ValueObjects\InsightAnalysisPeriodValueObject;
use Illuminate\Support\Facades\DB;

/**
 * @phpstan-type AnalysisPeriods array{
 *     current_month: DatePeriodValueObject,
 *     previous_month: DatePeriodValueObject,
 *     two_months_ago: DatePeriodValueObject,
 *     current_comparison?: DatePeriodValueObject,
 *     previous_comparison?: DatePeriodValueObject
 * }
 * @phpstan-type AnalysisRow object{
 *     has_history: bool
 *     period_key: string,
 *     total_amount: string,
 *     expense_count: int|string,
 *     largest_expense_amount: string,
 *     distinct_date_count: int|string,
 *     category: ?string,
 *     category_amount: ?string,
 *     largest_expense_category: ?string,
 *     largest_expense_description: ?string,
 *     largest_expense_occurred_on: ?string,
 * }
 */
final class EloquentExpenseAnalysisRepository implements ExpenseAnalysisRepository
{
    public function analyze(string $userId, InsightAnalysisPeriodValueObject $period): ExpenseAnalysisOutput
    {
        $periods = $period->periods();
        $rows = $this->fetchAggregatedExpenses(userId: $userId, periods: $periods);

        return $this->mapAnalysis(periods: $periods, rows: $rows, mode: $period->mode);
    }

    /**
     * @param  AnalysisPeriods  $periods
     * @param  non-empty-list<AnalysisRow>  $rows
     */
    private function mapAnalysis(array $periods, array $rows, InsightPeriodModeEnum $mode): ExpenseAnalysisOutput
    {
        $rowsByPeriod = [];

        foreach ($rows as $row) {
            $rowsByPeriod[$row->period_key][] = $row;
        }

        $projections = [];

        foreach ($periods as $key => $period) {
            $projections[$key] = $this->mapPeriod(
                period: $period,
                rows: $rowsByPeriod[$key],
            );
        }

        return new ExpenseAnalysisOutput(
            mode: $mode,
            currentMonth: $projections['current_month'],
            twoMonthsAgo: $projections['two_months_ago'],
            previousMonth: $projections['previous_month'],
            hasHistoricalExpenses: (bool) $rows[0]->has_history,
            currentComparison: $projections['current_comparison'] ?? null,
            previousComparison: $projections['previous_comparison'] ?? null,
        );
    }

    /** @param non-empty-list<AnalysisRow> $rows */
    private function mapPeriod(DatePeriodValueObject $period, array $rows): ExpensePeriodAnalysisOutput
    {
        $categories = [];

        foreach ($rows as $row) {
            if ($row->category !== null) {
                $categories[] = new ExpenseCategoryAnalysisOutput(
                    category: $row->category,
                    totalAmount: $row->category_amount,
                );
            }
        }

        $statistics = $rows[0];

        return new ExpensePeriodAnalysisOutput(
            period: $period,
            categories: $categories,
            totalAmount: $statistics->total_amount,
            expenseCount: (int) $statistics->expense_count,
            distinctDateCount: (int) $statistics->distinct_date_count,
            largestExpenseAmount: $statistics->largest_expense_amount,
            largestExpenseCategory: $statistics->largest_expense_category,
            largestExpenseOccurredOn: $statistics->largest_expense_occurred_on,
            largestExpenseDescription: $statistics->largest_expense_description,
        );
    }

    /**
     * @param  AnalysisPeriods  $periods
     * @return non-empty-list<AnalysisRow>
     */
    private function fetchAggregatedExpenses(string $userId, array $periods): array
    {
        $values = [];
        $bindings = [];

        foreach ($periods as $key => $period) {
            $values[] = '(CAST(? AS text), CAST(? AS date), CAST(? AS date))';
            array_push($bindings, $key, $period->from(), $period->to());
        }

        array_push(
            $bindings,
            $userId,
            $periods['two_months_ago']->from(),
            $periods['current_month']->to(),
            $userId,
            $userId,
            $periods['current_month']->to(),
        );
        $periodValues = implode(', ', $values);

        return DB::select(<<<SQL
            WITH periods (period_key, from_date, to_date) AS (
                VALUES {$periodValues}
            ), daily_expenses AS MATERIALIZED (
                SELECT occurred_on, category, COUNT(*) AS expense_count, SUM(amount) AS total_amount
                FROM expenses
                WHERE user_id = ? AND occurred_on BETWEEN CAST(? AS date) AND CAST(? AS date)
                GROUP BY occurred_on, category
            ), period_expenses AS MATERIALIZED (
                SELECT periods.period_key, expenses.*
                FROM periods
                JOIN daily_expenses expenses ON expenses.occurred_on BETWEEN periods.from_date AND periods.to_date
            ), totals AS (
                SELECT period_key, SUM(expense_count) AS expense_count,
                       COUNT(DISTINCT occurred_on) AS distinct_date_count, SUM(total_amount) AS total_amount
                FROM period_expenses
                GROUP BY period_key
            ), categories AS (
                SELECT period_key, category, SUM(total_amount) AS category_amount
                FROM period_expenses
                GROUP BY period_key, category
            ), largest AS MATERIALIZED (
                SELECT periods.period_key, expense.*
                FROM periods
                LEFT JOIN LATERAL (
                    SELECT amount, category, description, occurred_on
                    FROM expenses
                    WHERE user_id = ? AND occurred_on BETWEEN periods.from_date AND periods.to_date
                    ORDER BY amount DESC, category ASC, id ASC
                    LIMIT 1
                ) expense ON TRUE
            )
            SELECT periods.period_key,
                   COALESCE(totals.expense_count, 0) AS expense_count,
                   COALESCE(totals.distinct_date_count, 0) AS distinct_date_count,
                   CAST(COALESCE(totals.total_amount, 0) AS text) AS total_amount,
                   CAST(COALESCE(largest.amount, 0) AS text) AS largest_expense_amount,
                   largest.category AS largest_expense_category,
                   largest.description AS largest_expense_description,
                   TO_CHAR(largest.occurred_on, 'YYYY-MM-DD') AS largest_expense_occurred_on,
                   categories.category,
                   CAST(categories.category_amount AS text) AS category_amount,
                   EXISTS (SELECT 1 FROM expenses WHERE user_id = ? AND occurred_on <= CAST(? AS date)) AS has_history
            FROM periods
            LEFT JOIN totals USING (period_key)
            LEFT JOIN largest USING (period_key)
            LEFT JOIN categories USING (period_key)
            ORDER BY periods.period_key, categories.category
            SQL, $bindings);
    }
}
