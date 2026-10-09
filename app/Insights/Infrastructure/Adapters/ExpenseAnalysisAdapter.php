<?php

declare(strict_types=1);

namespace App\Insights\Infrastructure\Adapters;

use App\Insights\Application\Data\ExpenseAnalysisOutput;
use App\Insights\Application\Data\ExpenseCategoryAnalysisOutput;
use App\Insights\Application\Data\ExpensePeriodAnalysisOutput;
use App\Insights\Application\Ports\ExpenseAnalysisPort;
use App\Insights\Domain\ValueObjects\InsightPeriodValueObject;
use DateTimeImmutable;
use DateTimeZone;
use Illuminate\Support\Facades\DB;

/**
 * @phpstan-type AnalysisPeriods array{
 *     current_month: InsightPeriodValueObject,
 *     previous_month: InsightPeriodValueObject,
 *     two_months_ago: InsightPeriodValueObject,
 *     current_comparison?: InsightPeriodValueObject,
 *     previous_comparison?: InsightPeriodValueObject
 * }
 * @phpstan-type AnalysisRow object{
 *     period_key: string,
 *     expense_count: int|string,
 *     distinct_date_count: int|string,
 *     total_amount: string,
 *     largest_expense_amount: string,
 *     largest_expense_category: ?string,
 *     category: ?string,
 *     category_amount: ?string,
 *     has_history: bool
 * }
 */
final class ExpenseAnalysisAdapter implements ExpenseAnalysisPort
{
    public function analyze(int $userId, string $referenceDate): ExpenseAnalysisOutput
    {
        $periods = $this->buildPeriods(referenceDate: $referenceDate);
        $rows = $this->fetchAggregatedExpenses(userId: $userId, periods: $periods);

        return $this->mapAnalysis(periods: $periods, rows: $rows);
    }

    /** @return AnalysisPeriods */
    private function buildPeriods(string $referenceDate): array
    {
        InsightPeriodValueObject::fromDates(from: $referenceDate, to: $referenceDate);

        $reference = new DateTimeImmutable($referenceDate, new DateTimeZone('UTC'));
        $currentMonth = $reference->modify('first day of this month');
        $previousMonth = $currentMonth->modify('-1 month');
        $twoMonthsAgo = $currentMonth->modify('-2 months');
        $periods = [
            'current_month' => InsightPeriodValueObject::fromDates($currentMonth->format('Y-m-d'), $referenceDate),
            'previous_month' => InsightPeriodValueObject::fromDates($previousMonth->format('Y-m-d'), $currentMonth->modify('-1 day')->format('Y-m-d')),
            'two_months_ago' => InsightPeriodValueObject::fromDates($twoMonthsAgo->format('Y-m-d'), $previousMonth->modify('-1 day')->format('Y-m-d')),
        ];
        $comparisonDays = min((int) $reference->format('j') - 1, (int) $previousMonth->format('t'));

        if ($comparisonDays > 0) {
            $periods['current_comparison'] = InsightPeriodValueObject::fromDates(
                $currentMonth->format('Y-m-d'),
                $currentMonth->modify('+'.($comparisonDays - 1).' days')->format('Y-m-d'),
            );
            $periods['previous_comparison'] = InsightPeriodValueObject::fromDates(
                $previousMonth->format('Y-m-d'),
                $previousMonth->modify('+'.($comparisonDays - 1).' days')->format('Y-m-d'),
            );
        }

        return $periods;
    }

    /**
     * @param  AnalysisPeriods  $periods
     * @param  non-empty-list<AnalysisRow>  $rows
     */
    private function mapAnalysis(array $periods, array $rows): ExpenseAnalysisOutput
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
            currentMonth: $projections['current_month'],
            twoMonthsAgo: $projections['two_months_ago'],
            previousMonth: $projections['previous_month'],
            hasHistoricalExpenses: (bool) $rows[0]->has_history,
            currentComparison: $projections['current_comparison'] ?? null,
            previousComparison: $projections['previous_comparison'] ?? null,
        );
    }

    /** @param non-empty-list<AnalysisRow> $rows */
    private function mapPeriod(InsightPeriodValueObject $period, array $rows): ExpensePeriodAnalysisOutput
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
        );
    }

    /**
     * @param  AnalysisPeriods  $periods
     * @return non-empty-list<AnalysisRow>
     */
    private function fetchAggregatedExpenses(int $userId, array $periods): array
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
            $periods['current_month']->to(),
        );
        $periodValues = implode(', ', $values);

        return DB::select(<<<SQL
            WITH periods (period_key, from_date, to_date) AS (
                VALUES {$periodValues}
            ), scoped_expenses AS MATERIALIZED (
                SELECT id, amount, occurred_on, category
                FROM expenses
                WHERE user_id = ? AND occurred_on BETWEEN CAST(? AS date) AND CAST(? AS date)
            ), period_expenses AS MATERIALIZED (
                SELECT periods.period_key, expenses.*
                FROM periods
                JOIN scoped_expenses expenses ON expenses.occurred_on BETWEEN periods.from_date AND periods.to_date
            ), totals AS (
                SELECT period_key, COUNT(*) AS expense_count,
                       COUNT(DISTINCT occurred_on) AS distinct_date_count, SUM(amount) AS total_amount
                FROM period_expenses
                GROUP BY period_key
            ), categories AS (
                SELECT period_key, category, SUM(amount) AS category_amount
                FROM period_expenses
                GROUP BY period_key, category
            ), largest AS (
                SELECT DISTINCT ON (period_key) period_key, amount, category
                FROM period_expenses
                ORDER BY period_key, amount DESC, category ASC, id ASC
            )
            SELECT periods.period_key,
                   COALESCE(totals.expense_count, 0) AS expense_count,
                   COALESCE(totals.distinct_date_count, 0) AS distinct_date_count,
                   CAST(COALESCE(totals.total_amount, 0) AS text) AS total_amount,
                   CAST(COALESCE(largest.amount, 0) AS text) AS largest_expense_amount,
                   largest.category AS largest_expense_category,
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
