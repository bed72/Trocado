<?php

declare(strict_types=1);

namespace App\Insights\Application\UseCases;

use App\Core\Domain\ValueObjects\AmountValueObject;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Application\Data\ExpenseAnalysisOutput;
use App\Insights\Application\Data\ExpensePeriodAnalysisOutput;
use App\Insights\Domain\Enums\InsightHistoryStateEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use App\Insights\Domain\ValueObjects\ExpensePeriodSummaryValueObject;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;
use DateTimeImmutable;
use DateTimeZone;

final class GenerateInsightCandidatesUseCase
{
    private const int MinimumExpenseCount = 5;

    private const int MinimumDistinctDates = 3;

    private const int MinimumOtherPercent = 50;

    private const int MinimumComparisonDays = 7;

    private const int MinimumExpensePercent = 40;

    private const int MinimumCategoryPercent = 30;

    private const int MinimumVariationPercent = 20;

    private const string MinimumTotalAmount = '10000';

    private const string MinimumDifferenceAmount = '5000';

    /** @return list<InsightCandidateValueObject> */
    public function execute(ExpenseAnalysisOutput $analysis): array
    {
        $current = $this->mapPeriod($analysis->currentMonth);

        if (! $analysis->hasHistoricalExpenses) {
            if ($current->expenseCount > 0 || $analysis->previousMonth->expenseCount > 0 || $analysis->twoMonthsAgo->expenseCount > 0) {
                throw new InvalidInsightAnalysisException('Uma análise com registros não pode indicar ausência de histórico.');
            }

            return [new InsightCandidateValueObject(
                analysisPeriod: $current->period,
                type: InsightTypeEnum::FirstExpense,
            )];
        }

        if (($analysis->currentComparison === null) !== ($analysis->previousComparison === null)) {
            throw new InvalidInsightAnalysisException('As janelas de comparação devem ser fornecidas em conjunto.');
        }

        $candidates = $this->generateObservations(
            current: $current,
            previous: $this->mapPeriod($analysis->previousMonth),
            twoMonthsAgo: $this->mapPeriod($analysis->twoMonthsAgo),
        );

        if ($analysis->currentComparison !== null && $analysis->previousComparison !== null) {
            $comparison = $this->generateComparison(
                referenceDate: $current->period->to(),
                current: $this->mapPeriod($analysis->currentComparison),
                previous: $this->mapPeriod($analysis->previousComparison),
            );

            if ($comparison !== null) {
                $candidates[] = $comparison;
            }
        }

        return [...$candidates, ...$this->generateHistoryGuidance(
            current: $current,
            candidates: $candidates,
        )];
    }

    /** @return list<InsightCandidateValueObject> */
    private function generateObservations(
        ExpensePeriodSummaryValueObject $current,
        ExpensePeriodSummaryValueObject $previous,
        ExpensePeriodSummaryValueObject $twoMonthsAgo,
    ): array {
        if (! $current->period->startsAtMonthStart()
            || substr($current->period->from(), 0, 7) !== substr($current->period->to(), 0, 7)) {
            throw new InvalidInsightAnalysisException('As observações exigem um período corrente do início do mês até a referência.');
        }

        if (! $this->hasDescriptiveBase($current)) {
            return [];
        }

        $candidates = [];
        $leader = $this->eligibleLeadingCategory($current);

        if ($leader !== null) {
            $candidates[] = new InsightCandidateValueObject(
                category: $leader,
                analysisPeriod: $current->period,
                type: InsightTypeEnum::CategoryConcentration,
                ratio: $current->categoryAmount($leader)->shareOf($current->totalAmount),
            );

            if ($this->hasRecurringLeadership($leader, $current, $previous, $twoMonthsAgo)) {
                $candidates[] = new InsightCandidateValueObject(
                    category: $leader,
                    type: InsightTypeEnum::CategoryLeadStreak,
                    analysisPeriod: DatePeriodValueObject::fromDates($twoMonthsAgo->period->from(), $current->period->to()),
                );
            }
        }

        $expenseShare = $current->largestExpenseAmount->shareOf($current->totalAmount);

        if ($expenseShare->isAtLeastPercent(self::MinimumExpensePercent)) {
            $candidates[] = new InsightCandidateValueObject(
                ratio: $expenseShare,
                analysisPeriod: $current->period,
                category: $current->largestExpenseCategory,
                type: InsightTypeEnum::ExpenseConcentration,
            );
        }

        $otherShare = $current->categoryAmount('other')->shareOf($current->totalAmount);

        if ($otherShare->isAtLeastPercent(self::MinimumOtherPercent)) {
            $candidates[] = new InsightCandidateValueObject(
                category: 'other',
                ratio: $otherShare,
                analysisPeriod: $current->period,
                type: InsightTypeEnum::CategoryReview,
            );
        }

        return $candidates;
    }

    private function generateComparison(
        ExpensePeriodSummaryValueObject $current,
        ExpensePeriodSummaryValueObject $previous,
        string $referenceDate,
    ): ?InsightCandidateValueObject {
        DatePeriodValueObject::fromDates($referenceDate, $referenceDate);
        $reference = new DateTimeImmutable($referenceDate, new DateTimeZone('UTC'));
        $previousStart = new DateTimeImmutable($previous->period->from(), new DateTimeZone('UTC'));
        $commonDays = min((int) $reference->format('j') - 1, (int) $previousStart->format('t'));

        if (! $current->period->startsAtMonthStart() || ! $previous->period->startsAtMonthStart()
            || substr($current->period->from(), 0, 7) !== substr($referenceDate, 0, 7)
            || $current->period->to() >= $referenceDate
            || ! $previous->period->isPreviousMonthOf($current->period)
            || ! $current->period->hasSameDurationAs($previous->period)
            || $current->period->days() !== $commonDays
            || $current->period->days() < self::MinimumComparisonDays
            || ! $this->hasDescriptiveBase($current)
            || ! $this->hasDescriptiveBase($previous)) {
            return null;
        }

        $difference = $current->totalAmount->absoluteDifference($previous->totalAmount);
        $variation = $difference->shareOf($previous->totalAmount);

        if (! $difference->isAtLeast(self::MinimumDifferenceAmount)
            || ! $variation->isAtLeastPercent(self::MinimumVariationPercent)) {
            return null;
        }

        return new InsightCandidateValueObject(
            type: $current->totalAmount->compareTo($previous->totalAmount) > 0
                ? InsightTypeEnum::RegisteredAmountIncrease
                : InsightTypeEnum::RegisteredAmountDecrease,
            ratio: $variation,
            analysisPeriod: $current->period,
            comparisonPeriod: $previous->period,
        );
    }

    /**
     * @param  list<InsightCandidateValueObject>  $candidates
     * @return list<InsightCandidateValueObject>
     */
    private function generateHistoryGuidance(ExpensePeriodSummaryValueObject $current, array $candidates): array
    {
        foreach ($candidates as $candidate) {
            if ($candidate->isFinancialObservation()) {
                return [];
            }
        }

        return [new InsightCandidateValueObject(
            analysisPeriod: $current->period,
            type: InsightTypeEnum::InsufficientHistory,
            historyState: $current->expenseCount > 0 ? InsightHistoryStateEnum::CurrentExpenses : InsightHistoryStateEnum::NoCurrentExpenses,
        )];
    }

    private function hasRecurringLeadership(
        string $leader,
        ExpensePeriodSummaryValueObject $current,
        ExpensePeriodSummaryValueObject $previous,
        ExpensePeriodSummaryValueObject $twoMonthsAgo,
    ): bool {
        return $previous->period->isCompleteMonth()
            && $twoMonthsAgo->period->isCompleteMonth()
            && $previous->period->isPreviousMonthOf($current->period)
            && $twoMonthsAgo->period->isPreviousMonthOf($previous->period)
            && $this->eligibleLeadingCategory($previous) === $leader
            && $this->eligibleLeadingCategory($twoMonthsAgo) === $leader;
    }

    private function hasDescriptiveBase(ExpensePeriodSummaryValueObject $summary): bool
    {
        return $summary->expenseCount >= self::MinimumExpenseCount
            && $summary->distinctDateCount >= self::MinimumDistinctDates
            && $summary->totalAmount->isAtLeast(self::MinimumTotalAmount);
    }

    private function eligibleLeadingCategory(ExpensePeriodSummaryValueObject $summary): ?string
    {
        if (! $this->hasDescriptiveBase($summary)) {
            return null;
        }

        $leader = $summary->uniqueLeadingCategory();

        if ($leader === null || $leader === 'other'
            || ! $summary->categoryAmount($leader)->shareOf($summary->totalAmount)->isAtLeastPercent(self::MinimumCategoryPercent)) {
            return null;
        }

        return $leader;
    }

    private function mapPeriod(ExpensePeriodAnalysisOutput $projection): ExpensePeriodSummaryValueObject
    {
        $categories = [];

        foreach ($projection->categories as $category) {
            if (isset($categories[$category->category])) {
                throw new InvalidInsightAnalysisException('A projeção contém categorias duplicadas.');
            }

            $categories[$category->category] = AmountValueObject::fromAmount($category->totalAmount);
        }

        return new ExpensePeriodSummaryValueObject(
            categories: $categories,
            period: $projection->period,
            expenseCount: $projection->expenseCount,
            distinctDateCount: $projection->distinctDateCount,
            largestExpenseCategory: $projection->largestExpenseCategory,
            totalAmount: AmountValueObject::fromAmount($projection->totalAmount),
            largestExpenseAmount: AmountValueObject::fromAmount($projection->largestExpenseAmount),
        );
    }
}
