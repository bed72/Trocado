<?php

declare(strict_types=1);

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Application\Data\ExpenseAnalysisOutput;
use App\Insights\Application\Data\ExpenseCategoryAnalysisOutput;
use App\Insights\Application\Data\ExpensePeriodAnalysisOutput;
use App\Insights\Application\UseCases\GenerateInsightCandidatesUseCase;
use App\Insights\Domain\Enums\InsightHistoryStateEnum;
use App\Insights\Domain\Enums\InsightPeriodModeEnum;
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
        largestExpenseOccurredOn: $empty ? null : $from,
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
        ->and($candidates[0]->ratio->numerator->amount())->toBe('30000')
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

it('compares complete historical totals with unchanged material thresholds', function (string $current, string $previous, ?InsightTypeEnum $type, ?string $percent): void {
    $analysis = new ExpenseAnalysisOutput(
        mode: InsightPeriodModeEnum::Closed,
        hasHistoricalExpenses: true,
        currentMonth: candidateProjection('2026-09-01', '2026-09-30', $current),
        previousMonth: candidateProjection('2026-08-01', '2026-08-31', $previous),
        twoMonthsAgo: candidateProjection('2026-07-01', '2026-07-31', '0'),
        currentComparison: candidateProjection('2026-09-01', '2026-09-30', $current),
        previousComparison: candidateProjection('2026-08-01', '2026-08-31', $previous),
    );
    $candidates = candidateUseCase()->execute($analysis);
    $comparisons = array_values(array_filter($candidates, static fn (InsightCandidateValueObject $candidate): bool => in_array($candidate->type, [InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease], true)));

    if ($type === null) {
        expect($comparisons)->toBe([]);

        return;
    }

    expect($comparisons)->toHaveCount(1)
        ->and($comparisons[0]->type)->toBe($type)
        ->and($comparisons[0]->ratio->roundedPercent())->toBe($percent)
        ->and($comparisons[0]->ratio->numerator->amount())->toBe($type === InsightTypeEnum::RegisteredAmountIncrease ? '10000' : '15000')
        ->and($comparisons[0]->mode)->toBe(InsightPeriodModeEnum::Closed)
        ->and($comparisons[0]->analysisPeriod->to())->toBe('2026-09-30')
        ->and($comparisons[0]->comparisonPeriod->to())->toBe('2026-08-31');
})->with([
    'increase full 30 versus 31 days' => ['50000', '40000', InsightTypeEnum::RegisteredAmountIncrease, '25'],
    'decrease' => ['35000', '50000', InsightTypeEnum::RegisteredAmountDecrease, '30'],
    'difference below fifty reais' => ['12500', '10000', null, null],
    'zero denominator' => ['10000', '0', null, null],
    'previous base below minimum' => ['20000', '7000', null, null],
]);

it('does not treat an empty historical selection as the first expense', function (): void {
    $candidates = candidateUseCase()->execute(new ExpenseAnalysisOutput(
        mode: InsightPeriodModeEnum::Closed, hasHistoricalExpenses: false,
        currentMonth: candidateProjection('2026-09-01', '2026-09-30', '0'),
        previousMonth: candidateProjection('2026-08-01', '2026-08-31', '0'),
        twoMonthsAgo: candidateProjection('2026-07-01', '2026-07-31', '0'),
        currentComparison: candidateProjection('2026-09-01', '2026-09-30', '0'),
        previousComparison: candidateProjection('2026-08-01', '2026-08-31', '0'),
    ));

    expect($candidates)->toHaveCount(1)
        ->and($candidates[0]->type)->toBe(InsightTypeEnum::InsufficientHistory)
        ->and($candidates[0]->mode)->toBe(InsightPeriodModeEnum::Closed)
        ->and($candidates[0]->historyState)->toBe(InsightHistoryStateEnum::NoCurrentExpenses);
});

it('rejects inconsistent category totals at the domain boundary', function (): void {
    $projection = new ExpensePeriodAnalysisOutput(
        expenseCount: 5,
        distinctDateCount: 3,
        totalAmount: '10000',
        largestExpenseAmount: '2000',
        largestExpenseCategory: 'food',
        largestExpenseOccurredOn: '2026-10-01',
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

it('carries the selected expense description occurrence and exact amount into its candidate without interpretation', function (): void {
    $projection = new ExpensePeriodAnalysisOutput(
        expenseCount: 5, distinctDateCount: 3, totalAmount: '222222', largestExpenseAmount: '120000',
        largestExpenseCategory: 'housing', largestExpenseDescription: " <b>Aluguel</b>\n mensal ",
        largestExpenseOccurredOn: '2026-10-05', period: DatePeriodValueObject::fromDates('2026-10-01', '2026-10-12'),
        categories: [new ExpenseCategoryAnalysisOutput('housing', '120000'), new ExpenseCategoryAnalysisOutput('other', '102222')],
    );
    $candidates = candidateUseCase()->execute(new ExpenseAnalysisOutput(
        currentComparison: null, previousComparison: null,
        hasHistoricalExpenses: true, currentMonth: $projection,
        twoMonthsAgo: candidateProjection('2026-08-01', '2026-08-31', '0'),
        previousMonth: candidateProjection('2026-09-01', '2026-09-30', '0'),
    ));
    $expense = array_values(array_filter($candidates, static fn (InsightCandidateValueObject $candidate): bool => $candidate->type === InsightTypeEnum::ExpenseConcentration))[0];

    expect($expense->expenseDescription)->toBe(" <b>Aluguel</b>\n mensal ")
        ->and($expense->expenseOccurredOn)->toBe('2026-10-05')
        ->and($expense->category)->toBe('housing')
        ->and($expense->ratio->numerator->amount())->toBe('120000')
        ->and($expense->ratio->denominator->amount())->toBe('222222');
});
