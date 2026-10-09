<?php

declare(strict_types=1);

use App\Insights\Application\UseCases\SelectInsightCandidatesUseCase;
use App\Insights\Domain\Enums\InsightHistoryStateEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\ValueObjects\InsightAmountValueObject;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;
use App\Insights\Domain\ValueObjects\InsightPeriodValueObject;

function selectionCandidate(
    InsightTypeEnum $type,
    ?string $category = null,
    string $from = '2026-10-01',
    string $to = '2026-10-12',
    ?InsightPeriodValueObject $comparison = null,
): InsightCandidateValueObject {
    $withRatio = in_array($type, [InsightTypeEnum::CategoryConcentration, InsightTypeEnum::ExpenseConcentration,
        InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease, InsightTypeEnum::CategoryReview], true);

    return new InsightCandidateValueObject(
        type: $type,
        category: $category,
        comparisonPeriod: $comparison,
        analysisPeriod: InsightPeriodValueObject::fromDates($from, $to),
        historyState: $type === InsightTypeEnum::InsufficientHistory ? InsightHistoryStateEnum::CurrentExpenses : null,
        ratio: $withRatio ? InsightAmountValueObject::fromCents('6000')->shareOf(InsightAmountValueObject::fromCents('10000')) : null,
    );
}

it('orders candidates by the approved priorities without changing the input', function (): void {
    $comparison = selectionCandidate(InsightTypeEnum::RegisteredAmountIncrease, to: '2026-10-11',
        comparison: InsightPeriodValueObject::fromDates('2026-09-01', '2026-09-11'));
    $streak = selectionCandidate(InsightTypeEnum::CategoryLeadStreak, 'food', from: '2026-08-01');
    $category = selectionCandidate(InsightTypeEnum::CategoryConcentration, 'health');
    $expense = selectionCandidate(InsightTypeEnum::ExpenseConcentration, 'transport');
    $review = selectionCandidate(InsightTypeEnum::CategoryReview, 'other');
    $input = [$review, $expense, $category, $streak, $comparison];
    $original = $input;

    $selected = (new SelectInsightCandidatesUseCase)->execute($input);

    expect($selected)->toBe([$comparison, $streak, $category, $expense, $review])
        ->and($input)->toBe($original);
});

it('lets recurring leadership replace the same current category and largest expense', function (bool $reversed): void {
    $streak = selectionCandidate(InsightTypeEnum::CategoryLeadStreak, 'food', from: '2026-08-01');
    $category = selectionCandidate(InsightTypeEnum::CategoryConcentration, 'food');
    $expense = selectionCandidate(InsightTypeEnum::ExpenseConcentration, 'food');
    $input = [$category, $expense, $streak];

    expect((new SelectInsightCandidatesUseCase)->execute($reversed ? array_reverse($input) : $input))->toBe([$streak]);
})->with([true, false]);

it('preserves other subjects and periods beside recurring leadership', function (): void {
    $streak = selectionCandidate(InsightTypeEnum::CategoryLeadStreak, 'food', from: '2026-08-01');
    $otherCategory = selectionCandidate(InsightTypeEnum::CategoryConcentration, 'health');
    $previousPeriod = selectionCandidate(InsightTypeEnum::CategoryConcentration, 'food', from: '2026-09-01', to: '2026-09-30');
    $differentEnd = selectionCandidate(InsightTypeEnum::ExpenseConcentration, 'food', to: '2026-10-11');

    expect((new SelectInsightCandidatesUseCase)->execute([$otherCategory, $differentEnd, $previousPeriod, $streak]))
        ->toBe([$streak, $previousPeriod, $otherCategory, $differentEnd]);
});

it('suppresses a largest expense only when category and period match the selected concentration', function (
    string $expenseCategory,
    string $expenseFrom,
    string $expenseTo,
    bool $redundant,
): void {
    $category = selectionCandidate(InsightTypeEnum::CategoryConcentration, 'food');
    $expense = selectionCandidate(InsightTypeEnum::ExpenseConcentration, $expenseCategory, $expenseFrom, $expenseTo);

    expect((new SelectInsightCandidatesUseCase)->execute([$expense, $category]))
        ->toBe($redundant ? [$category] : [$category, $expense]);
})->with([
    ['food', '2026-10-01', '2026-10-12', true],
    ['health', '2026-10-01', '2026-10-12', false],
    ['food', '2026-09-01', '2026-09-30', false],
    ['food', '2026-10-01', '2026-10-11', false],
    ['food', '2026-10-02', '2026-10-12', false],
]);

it('deduplicates separate candidate objects representing the same information', function (): void {
    $candidate = selectionCandidate(InsightTypeEnum::CategoryConcentration, 'food');
    $duplicate = selectionCandidate(InsightTypeEnum::CategoryConcentration, 'food');

    expect((new SelectInsightCandidatesUseCase)->execute([$candidate, $duplicate, $candidate]))->toBe([$candidate]);
});

it('keeps distinct comparison periods rather than deduplicating only by type', function (): void {
    $previousMonth = selectionCandidate(InsightTypeEnum::RegisteredAmountIncrease, to: '2026-10-11',
        comparison: InsightPeriodValueObject::fromDates('2026-09-01', '2026-09-11'));
    $olderMonth = selectionCandidate(InsightTypeEnum::RegisteredAmountIncrease, to: '2026-10-11',
        comparison: InsightPeriodValueObject::fromDates('2026-08-01', '2026-08-11'));

    expect((new SelectInsightCandidatesUseCase)->execute([$previousMonth, $olderMonth]))->toBe([$olderMonth, $previousMonth]);
});

it('keeps category review alongside a different financial fact even when both concern other', function (): void {
    $review = selectionCandidate(InsightTypeEnum::CategoryReview, 'other');
    $expense = selectionCandidate(InsightTypeEnum::ExpenseConcentration, 'other');

    expect((new SelectInsightCandidatesUseCase)->execute([$review, $expense]))->toBe([$expense, $review]);
});

it('keeps category review and at most one repeated history guidance candidate', function (): void {
    $review = selectionCandidate(InsightTypeEnum::CategoryReview, 'other');
    $history = selectionCandidate(InsightTypeEnum::InsufficientHistory);
    $duplicate = selectionCandidate(InsightTypeEnum::InsufficientHistory);

    expect((new SelectInsightCandidatesUseCase)->execute([$history, $review, $duplicate]))->toBe([$review, $history]);
});

it('preserves the single first expense candidate for an account without history', function (): void {
    $first = selectionCandidate(InsightTypeEnum::FirstExpense);

    expect((new SelectInsightCandidatesUseCase)->execute([$first, selectionCandidate(InsightTypeEnum::FirstExpense)]))->toBe([$first]);
});

it('returns an empty list without manufacturing candidates', function (): void {
    expect((new SelectInsightCandidatesUseCase)->execute([]))->toBe([]);
});

it('uses deterministic category and period tie breakers regardless of input order', function (): void {
    $foodEarlier = selectionCandidate(InsightTypeEnum::CategoryConcentration, 'food', to: '2026-10-11');
    $foodCurrent = selectionCandidate(InsightTypeEnum::CategoryConcentration, 'food');
    $health = selectionCandidate(InsightTypeEnum::CategoryConcentration, 'health');
    $expected = [$foodEarlier, $foodCurrent, $health];
    $inputs = [
        [$foodEarlier, $foodCurrent, $health],
        [$foodEarlier, $health, $foodCurrent],
        [$foodCurrent, $foodEarlier, $health],
        [$foodCurrent, $health, $foodEarlier],
        [$health, $foodEarlier, $foodCurrent],
        [$health, $foodCurrent, $foodEarlier],
    ];

    foreach ($inputs as $input) {
        expect((new SelectInsightCandidatesUseCase)->execute($input))->toBe($expected);
    }
});

it('gives both comparison directions equal priority and breaks ties by type', function (): void {
    $increase = selectionCandidate(InsightTypeEnum::RegisteredAmountIncrease, to: '2026-10-11',
        comparison: InsightPeriodValueObject::fromDates('2026-09-01', '2026-09-11'));
    $decrease = selectionCandidate(InsightTypeEnum::RegisteredAmountDecrease, from: '2026-09-01', to: '2026-09-11',
        comparison: InsightPeriodValueObject::fromDates('2026-08-01', '2026-08-11'));

    expect($increase->type->priority())->toBe($decrease->type->priority())
        ->and((new SelectInsightCandidatesUseCase)->execute([$increase, $decrease]))->toBe([$decrease, $increase])
        ->and((new SelectInsightCandidatesUseCase)->execute([$decrease, $increase]))->toBe([$decrease, $increase]);
});

it('applies the six candidate cap after removing redundant facts', function (): void {
    $categories = ['education', 'food', 'health', 'housing', 'leisure', 'shopping', 'transport'];
    $input = [];

    foreach ($categories as $category) {
        $candidate = selectionCandidate(InsightTypeEnum::CategoryConcentration, $category);
        $input[] = $candidate;
        $input[] = selectionCandidate(InsightTypeEnum::ExpenseConcentration, $category);
        $input[] = $candidate;
    }

    $selected = (new SelectInsightCandidatesUseCase)->execute(array_reverse($input));

    expect($selected)->toHaveCount(6)
        ->and(array_map(static fn (InsightCandidateValueObject $candidate): ?string => $candidate->category, $selected))
        ->toBe(['education', 'food', 'health', 'housing', 'leisure', 'shopping']);
});
