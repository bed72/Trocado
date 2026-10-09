<?php

declare(strict_types=1);

use App\Insights\Domain\Enums\InsightHistoryStateEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use App\Insights\Domain\ValueObjects\InsightAmountValueObject;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;
use App\Insights\Domain\ValueObjects\InsightPeriodValueObject;

function candidateValueObjectFixture(
    InsightTypeEnum $type,
    ?string $category,
    bool $withRatio,
    bool $withComparison,
    ?InsightHistoryStateEnum $historyState = null,
    string $previousTo = '2026-09-11',
): InsightCandidateValueObject {
    return new InsightCandidateValueObject(
        type: $type,
        category: $category,
        historyState: $historyState,
        analysisPeriod: InsightPeriodValueObject::fromDates('2026-10-01', '2026-10-11'),
        comparisonPeriod: $withComparison ? InsightPeriodValueObject::fromDates('2026-09-01', $previousTo) : null,
        ratio: $withRatio ? InsightAmountValueObject::fromCents('5000')->shareOf(InsightAmountValueObject::fromCents('10000')) : null,
    );
}

it('preserves valid facts and distinguishes financial observations from onboarding', function (
    InsightTypeEnum $type,
    ?string $category,
    bool $withRatio,
    bool $withComparison,
    ?InsightHistoryStateEnum $historyState,
    bool $financial,
): void {
    $candidate = candidateValueObjectFixture($type, $category, $withRatio, $withComparison, $historyState);

    expect($candidate->type)->toBe($type)
        ->and($candidate->category)->toBe($category)
        ->and($candidate->historyState)->toBe($historyState)
        ->and($candidate->isFinancialObservation())->toBe($financial)
        ->and($candidate->period())->toBe($financial ? $candidate->analysisPeriod : null)
        ->and($candidate->analysisPeriod->from())->toBe('2026-10-01')
        ->and($candidate->ratio?->numerator->cents())->toBe($withRatio ? '5000' : null)
        ->and($candidate->ratio?->denominator->cents())->toBe($withRatio ? '10000' : null)
        ->and($candidate->comparisonPeriod?->to())->toBe($withComparison ? '2026-09-11' : null);
})->with([
    'category concentration' => [InsightTypeEnum::CategoryConcentration, 'food', true, false, null, true],
    'expense concentration in other' => [InsightTypeEnum::ExpenseConcentration, 'other', true, false, null, true],
    'amount increase' => [InsightTypeEnum::RegisteredAmountIncrease, null, true, true, null, true],
    'amount decrease' => [InsightTypeEnum::RegisteredAmountDecrease, null, true, true, null, true],
    'recurring category leadership' => [InsightTypeEnum::CategoryLeadStreak, 'food', false, false, null, true],
    'first expense' => [InsightTypeEnum::FirstExpense, null, false, false, null, false],
    'history with current expenses' => [InsightTypeEnum::InsufficientHistory, null, false, false, InsightHistoryStateEnum::CurrentExpenses, false],
    'history without current expenses' => [InsightTypeEnum::InsufficientHistory, null, false, false, InsightHistoryStateEnum::NoCurrentExpenses, false],
    'category review' => [InsightTypeEnum::CategoryReview, 'other', true, false, null, false],
]);

it('rejects missing or unrelated facts for the candidate type', function (
    InsightTypeEnum $type,
    ?string $category,
    bool $withRatio,
    bool $withComparison,
    ?InsightHistoryStateEnum $historyState,
): void {
    candidateValueObjectFixture($type, $category, $withRatio, $withComparison, $historyState);
})->with([
    'concentration without category' => [InsightTypeEnum::CategoryConcentration, null, true, false, null],
    'concentration without ratio' => [InsightTypeEnum::CategoryConcentration, 'food', false, false, null],
    'expense without category' => [InsightTypeEnum::ExpenseConcentration, null, true, false, null],
    'expense without ratio' => [InsightTypeEnum::ExpenseConcentration, 'food', false, false, null],
    'increase without comparison' => [InsightTypeEnum::RegisteredAmountIncrease, null, true, false, null],
    'decrease without ratio' => [InsightTypeEnum::RegisteredAmountDecrease, null, false, true, null],
    'comparison with category' => [InsightTypeEnum::RegisteredAmountIncrease, 'food', true, true, null],
    'streak without category' => [InsightTypeEnum::CategoryLeadStreak, null, false, false, null],
    'streak with ratio' => [InsightTypeEnum::CategoryLeadStreak, 'food', true, false, null],
    'category review without ratio' => [InsightTypeEnum::CategoryReview, 'other', false, false, null],
    'history without its contextual state' => [InsightTypeEnum::InsufficientHistory, null, false, false, null],
    'first expense with history state' => [InsightTypeEnum::FirstExpense, null, false, false, InsightHistoryStateEnum::CurrentExpenses],
    'first expense with category' => [InsightTypeEnum::FirstExpense, 'food', false, false, null],
    'first expense with ratio' => [InsightTypeEnum::FirstExpense, null, true, false, null],
    'observation with comparison period' => [InsightTypeEnum::CategoryConcentration, 'food', true, true, null],
])->throws(InvalidInsightAnalysisException::class, 'Os fatos do candidato não correspondem ao tipo de insight.');

it('rejects empty categories other leadership and review outside other', function (InsightTypeEnum $type, string $category, bool $withRatio): void {
    candidateValueObjectFixture($type, $category, $withRatio, false);
})->with([
    [InsightTypeEnum::CategoryConcentration, '', true],
    [InsightTypeEnum::ExpenseConcentration, '', true],
    [InsightTypeEnum::CategoryLeadStreak, '', false],
    [InsightTypeEnum::CategoryConcentration, 'other', true],
    [InsightTypeEnum::CategoryLeadStreak, 'other', false],
    [InsightTypeEnum::CategoryReview, 'food', true],
])->throws(InvalidInsightAnalysisException::class, 'A categoria não é válida para o candidato.');

it('rejects comparison periods of different durations', function (InsightTypeEnum $type): void {
    candidateValueObjectFixture($type, null, true, true, previousTo: '2026-09-10');
})->with([InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease])
    ->throws(InvalidInsightAnalysisException::class, 'Uma comparação exige períodos de mesma duração.');

it('preserves the full three period span for recurring leadership', function (): void {
    $span = InsightPeriodValueObject::fromDates('2026-08-01', '2026-10-12');
    $candidate = new InsightCandidateValueObject(
        type: InsightTypeEnum::CategoryLeadStreak,
        analysisPeriod: $span,
        category: 'food',
    );

    expect($candidate->period())->toBe($span)
        ->and($candidate->analysisPeriod->from())->toBe('2026-08-01')
        ->and($candidate->analysisPeriod->to())->toBe('2026-10-12')
        ->and($candidate->comparisonPeriod)->toBeNull()
        ->and($candidate->ratio)->toBeNull();
});
