<?php

declare(strict_types=1);

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Application\Data\ExpenseAnalysisOutput;
use App\Insights\Application\Data\ExpenseCategoryAnalysisOutput;
use App\Insights\Application\Data\ExpensePeriodAnalysisOutput;
use App\Insights\Application\UseCases\GenerateInsightCandidatesUseCase;
use App\Insights\Domain\Enums\InsightHistoryStateEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;

function candidateProjection(string $from, string $to, string $total = '10000'): ExpensePeriodAnalysisOutput
{
    $empty = $total === '0';

    return new ExpensePeriodAnalysisOutput(
        totalAmount: $total,
        expenseCount: $empty ? 0 : 5,
        distinctDateCount: $empty ? 0 : 3,
        largestExpenseAmount: $empty ? '0' : '2000',
        largestExpenseCategory: $empty ? null : 'food',
        period: DatePeriodValueObject::fromDates($from, $to),
        categories: $empty ? [] : [new ExpenseCategoryAnalysisOutput(category: 'food', totalAmount: $total)],
    );
}

function candidateUseCase(): GenerateInsightCandidatesUseCase
{
    return new GenerateInsightCandidatesUseCase;
}

it('converts analytical projections into independent domain candidates with original facts', function (): void {
    $analysis = new ExpenseAnalysisOutput(
        hasHistoricalExpenses: true,
        twoMonthsAgo: candidateProjection('2026-08-01', '2026-08-31', '25000'),
        currentMonth: candidateProjection('2026-10-01', '2026-10-12', '30000'),
        previousMonth: candidateProjection('2026-09-01', '2026-09-30', '25000'),
        currentComparison: candidateProjection('2026-10-01', '2026-10-11', '30000'),
        previousComparison: candidateProjection('2026-09-01', '2026-09-11', '25000'),
    );
    $candidates = candidateUseCase()->execute($analysis);
    $types = array_map(static fn (InsightCandidateValueObject $candidate): InsightTypeEnum => $candidate->type, $candidates);

    expect($types)->toEqualCanonicalizing([
        InsightTypeEnum::CategoryConcentration,
        InsightTypeEnum::CategoryLeadStreak,
        InsightTypeEnum::RegisteredAmountIncrease,
    ])
        ->and($candidates[0]->ratio->numerator->cents())->toBe('30000')
        ->and($candidates[0]->analysisPeriod->equals($analysis->currentMonth->period))->toBeTrue()
        ->and($analysis->currentMonth->totalAmount)->toBe('30000');
});

it('produces first expense alone without history and contextual guidance with old history', function (bool $history, InsightTypeEnum $type): void {
    $analysis = new ExpenseAnalysisOutput(
        currentComparison: null,
        previousComparison: null,
        hasHistoricalExpenses: $history,
        currentMonth: candidateProjection('2026-10-01', '2026-10-01', '0'),
        twoMonthsAgo: candidateProjection('2026-08-01', '2026-08-31', '0'),
        previousMonth: candidateProjection('2026-09-01', '2026-09-30', '0'),
    );
    $candidates = candidateUseCase()->execute($analysis);

    expect($candidates)->toHaveCount(1)
        ->and($candidates[0]->type)->toBe($type)
        ->and($candidates[0]->period())->toBeNull()
        ->and($candidates[0]->historyState)->toBe($history ? InsightHistoryStateEnum::NoCurrentExpenses : null);
})->with([
    [false, InsightTypeEnum::FirstExpense],
    [true, InsightTypeEnum::InsufficientHistory],
]);

it('rejects one sided analytical comparison projections', function (): void {
    candidateUseCase()->execute(new ExpenseAnalysisOutput(
        previousComparison: null,
        hasHistoricalExpenses: true,
        twoMonthsAgo: candidateProjection('2026-08-01', '2026-08-31'),
        currentMonth: candidateProjection('2026-10-01', '2026-10-12'),
        previousMonth: candidateProjection('2026-09-01', '2026-09-30'),
        currentComparison: candidateProjection('2026-10-01', '2026-10-11'),
    ));
})->throws(InvalidInsightAnalysisException::class);

it('rejects inconsistent category totals at the domain boundary', function (): void {
    $projection = new ExpensePeriodAnalysisOutput(
        expenseCount: 5,
        distinctDateCount: 3,
        totalAmount: '10000',
        largestExpenseAmount: '2000',
        largestExpenseCategory: 'food',
        period: DatePeriodValueObject::fromDates('2026-10-01', '2026-10-12'),
        categories: [new ExpenseCategoryAnalysisOutput(category: 'food', totalAmount: '9000')],
    );

    candidateUseCase()->execute(new ExpenseAnalysisOutput(
        currentComparison: null,
        previousComparison: null,
        currentMonth: $projection,
        hasHistoricalExpenses: true,
        twoMonthsAgo: candidateProjection('2026-08-01', '2026-08-31'),
        previousMonth: candidateProjection('2026-09-01', '2026-09-30'),
    ));
})->throws(InvalidInsightAnalysisException::class);
