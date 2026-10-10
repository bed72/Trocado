<?php

declare(strict_types=1);

use App\Core\Domain\ValueObjects\AmountValueObject;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Application\Data\ExpenseAnalysisOutput;
use App\Insights\Application\Data\ExpenseCategoryAnalysisOutput;
use App\Insights\Application\Data\ExpensePeriodAnalysisOutput;
use App\Insights\Application\UseCases\GenerateInsightCandidatesUseCase;
use App\Insights\Domain\Enums\InsightHistoryStateEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use App\Insights\Domain\ValueObjects\ExpensePeriodSummaryValueObject;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;

/** @param array<string, string> $categories */
function insightSummary(
    int $count = 5,
    int $dates = 3,
    string $largest = '2000',
    string $to = '2026-10-12',
    string $from = '2026-10-01',
    ?string $largestCategory = 'food',
    array $categories = ['food' => '6000', 'other' => '4000'],
): ExpensePeriodSummaryValueObject {
    $amounts = [];
    $total = AmountValueObject::fromAmount('0');

    foreach ($categories as $category => $amount) {
        $amounts[$category] = AmountValueObject::fromAmount($amount);
        $total = $total->plus($amounts[$category]);
    }

    return new ExpensePeriodSummaryValueObject(
        totalAmount: $total,
        categories: $amounts,
        expenseCount: $count,
        distinctDateCount: $dates,
        largestExpenseCategory: $largestCategory,
        period: DatePeriodValueObject::fromDates($from, $to),
        largestExpenseAmount: AmountValueObject::fromAmount($largest),
    );
}

function insightRulesProjection(ExpensePeriodSummaryValueObject $summary): ExpensePeriodAnalysisOutput
{
    $categories = [];

    foreach ($summary->categories as $category => $amount) {
        $categories[] = new ExpenseCategoryAnalysisOutput(category: $category, totalAmount: $amount->amount());
    }

    return new ExpensePeriodAnalysisOutput(
        categories: $categories,
        period: $summary->period,
        expenseCount: $summary->expenseCount,
        totalAmount: $summary->totalAmount->amount(),
        distinctDateCount: $summary->distinctDateCount,
        largestExpenseCategory: $summary->largestExpenseCategory,
        largestExpenseAmount: $summary->largestExpenseAmount->amount(),
    );
}

/** @return list<InsightCandidateValueObject> */
function insightRulesCandidates(
    ExpensePeriodSummaryValueObject $current,
    ?ExpensePeriodSummaryValueObject $previous = null,
    ?ExpensePeriodSummaryValueObject $twoMonthsAgo = null,
    ?ExpensePeriodSummaryValueObject $currentComparison = null,
    ?ExpensePeriodSummaryValueObject $previousComparison = null,
    bool $history = true,
): array {
    $start = new DateTimeImmutable($current->period->from(), new DateTimeZone('UTC'));
    $previousStart = $start->modify('first day of previous month');
    $olderStart = $previousStart->modify('first day of previous month');
    $previous ??= insightSummary(categories: [], count: 0, dates: 0, largest: '0', largestCategory: null,
        from: $previousStart->format('Y-m-d'), to: $previousStart->format('Y-m-t'));
    $twoMonthsAgo ??= insightSummary(categories: [], count: 0, dates: 0, largest: '0', largestCategory: null,
        from: $olderStart->format('Y-m-d'), to: $olderStart->format('Y-m-t'));

    return (new GenerateInsightCandidatesUseCase)->execute(new ExpenseAnalysisOutput(
        hasHistoricalExpenses: $history,
        currentMonth: insightRulesProjection($current),
        previousMonth: insightRulesProjection($previous),
        twoMonthsAgo: insightRulesProjection($twoMonthsAgo),
        currentComparison: $currentComparison === null ? null : insightRulesProjection($currentComparison),
        previousComparison: $previousComparison === null ? null : insightRulesProjection($previousComparison),
    ));
}

function insightRulesComparison(
    ExpensePeriodSummaryValueObject $current,
    ExpensePeriodSummaryValueObject $previous,
    string $referenceDate,
): ?InsightCandidateValueObject {
    $reference = new DateTimeImmutable($referenceDate, new DateTimeZone('UTC'));
    $currentMonth = insightSummary(from: $reference->format('Y-m-01'), to: $referenceDate);

    foreach (insightRulesCandidates($currentMonth, currentComparison: $current, previousComparison: $previous) as $candidate) {
        if (in_array($candidate->type, [InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease], true)) {
            return $candidate;
        }
    }

    return null;
}

/** @param list<InsightCandidateValueObject> $candidates */
function insightCandidateTypes(array $candidates): array
{
    return array_map(static fn (InsightCandidateValueObject $candidate): InsightTypeEnum => $candidate->type, $candidates);
}

it('requires all descriptive base thresholds', function (int $count, int $dates, string $total, bool $eligible): void {
    $summary = insightSummary(categories: ['food' => $total], count: $count, dates: $dates);

    expect(in_array(InsightTypeEnum::CategoryConcentration, insightCandidateTypes(insightRulesCandidates($summary)), true))->toBe($eligible);
})->with([
    [5, 3, '10000', true],
    [4, 3, '10000', false],
    [5, 2, '10000', false],
    [5, 3, '9999', false],
]);

it('requires a unique non other leader and the exact category threshold', function (array $categories, ?string $expected): void {
    $summary = insightSummary(categories: $categories);

    $leaders = array_values(array_filter(insightRulesCandidates($summary), static fn (InsightCandidateValueObject $candidate): bool => $candidate->type === InsightTypeEnum::CategoryConcentration));

    expect($leaders[0]->category ?? null)->toBe($expected);
})->with([
    [['food' => '3000', 'leisure' => '2500', 'transport' => '2500', 'other' => '2000'], 'food'],
    [['food' => '2999', 'leisure' => '2500', 'transport' => '2500', 'other' => '2001'], null],
    [['food' => '5000', 'other' => '5000'], null],
    [['food' => '4000', 'other' => '6000'], null],
]);

it('requires the unrounded expense concentration threshold', function (string $largest, bool $eligible): void {
    $summary = insightSummary(largest: $largest);
    $candidates = insightRulesCandidates($summary);

    expect(in_array(InsightTypeEnum::ExpenseConcentration, insightCandidateTypes($candidates), true))->toBe($eligible);
})->with([['3999', false], ['4000', true]]);

it('generates at most one concentration for the largest launch with its original ratio', function (): void {
    $summary = insightSummary(largest: '5000');
    $candidates = insightRulesCandidates($summary);
    $expenseCandidates = array_values(array_filter($candidates, static fn (InsightCandidateValueObject $candidate): bool => $candidate->type === InsightTypeEnum::ExpenseConcentration));

    expect($expenseCandidates)->toHaveCount(1)
        ->and($expenseCandidates[0]->category)->toBe('food')
        ->and($expenseCandidates[0]->ratio->numerator->amount())->toBe('5000')
        ->and($expenseCandidates[0]->ratio->denominator->amount())->toBe('10000');
});

it('compares totals only with sufficient absolute and relative differences', function (string $currentTotal, string $previousTotal, ?InsightTypeEnum $type): void {
    $current = insightSummary(categories: ['food' => $currentTotal], to: '2026-10-11');
    $previous = insightSummary(categories: ['food' => $previousTotal], from: '2026-09-01', to: '2026-09-11');
    $candidate = insightRulesComparison($current, $previous, '2026-10-12');

    expect($candidate?->type)->toBe($type);

    if ($candidate !== null) {
        expect($candidate->ratio->denominator->amount())->toBe($previousTotal)
            ->and($candidate->comparisonPeriod->equals($previous->period))->toBeTrue();
    }
})->with([
    ['30000', '25000', InsightTypeEnum::RegisteredAmountIncrease],
    ['35000', '50000', InsightTypeEnum::RegisteredAmountDecrease],
    ['12500', '10000', null],
    ['29999', '25000', null],
    ['119999', '100000', null],
    ['50000', '50000', null],
]);

it('rejects insufficient mismatched shifted incomplete or future comparison windows', function (string $from, string $to, string $previousFrom, string $previousTo, string $reference): void {
    $current = insightSummary(categories: ['food' => '30000'], from: $from, to: $to);
    $previous = insightSummary(categories: ['food' => '25000'], from: $previousFrom, to: $previousTo);

    expect(insightRulesComparison($current, $previous, $reference))->toBeNull();
})->with([
    ['2026-10-01', '2026-10-06', '2026-09-01', '2026-09-06', '2026-10-07'],
    ['2026-10-01', '2026-10-11', '2026-09-01', '2026-09-30', '2026-10-12'],
    ['2026-10-02', '2026-10-11', '2026-09-02', '2026-09-11', '2026-10-12'],
    ['2026-10-01', '2026-10-10', '2026-09-01', '2026-09-10', '2026-10-12'],
    ['2026-10-01', '2026-10-12', '2026-09-01', '2026-09-12', '2026-10-12'],
    ['2026-10-01', '2026-10-11', '2026-08-01', '2026-08-11', '2026-10-12'],
]);

it('does not compare empty or insufficient bases in either direction', function (bool $emptyCurrent): void {
    $empty = insightSummary(categories: [], count: 0, dates: 0, largest: '0', largestCategory: null,
        from: $emptyCurrent ? '2026-10-01' : '2026-09-01', to: $emptyCurrent ? '2026-10-11' : '2026-09-11');
    $eligible = insightSummary(from: $emptyCurrent ? '2026-09-01' : '2026-10-01', to: $emptyCurrent ? '2026-09-11' : '2026-10-11');

    expect(insightRulesComparison($emptyCurrent ? $empty : $eligible, $emptyCurrent ? $eligible : $empty, '2026-10-12'))->toBeNull();
})->with([true, false]);

it('compares large totals exactly and accepts the shared days of shorter months', function (): void {
    $current = insightSummary(categories: ['food' => '30000000000000000000'], largest: '6000000000000000000', to: '2027-03-28', from: '2027-03-01');
    $previous = insightSummary(categories: ['food' => '25000000000000000000'], largest: '5000000000000000000', from: '2027-02-01', to: '2027-02-28');
    $candidate = insightRulesComparison($current, $previous, '2027-03-31');

    expect($candidate->type)->toBe(InsightTypeEnum::RegisteredAmountIncrease)
        ->and($candidate->ratio->numerator->amount())->toBe('5000000000000000000')
        ->and($candidate->ratio->roundedPercent())->toBe('20');
});

it('keeps both concentration and streak candidates for later semantic selection', function (): void {
    $current = insightSummary();
    $previous = insightSummary(from: '2026-09-01', to: '2026-09-30');
    $older = insightSummary(from: '2026-08-01', to: '2026-08-31');
    $candidates = insightRulesCandidates($current, $previous, $older);

    expect(insightCandidateTypes($candidates))->toBe([InsightTypeEnum::CategoryConcentration, InsightTypeEnum::CategoryLeadStreak])
        ->and($candidates[1]->analysisPeriod->from())->toBe('2026-08-01')
        ->and($candidates[1]->analysisPeriod->to())->toBe('2026-10-12')
        ->and($candidates[1]->comparisonPeriod)->toBeNull();
});

it('requires complete consecutive eligible months without ties for a streak', function (array $categories, int $count, string $from, string $to): void {
    $current = insightSummary();
    $previous = insightSummary(from: '2026-09-01', to: '2026-09-30');
    $older = insightSummary(categories: $categories, count: $count, from: $from, to: $to);
    $types = insightCandidateTypes(insightRulesCandidates($current, $previous, $older));

    expect($types)->toContain(InsightTypeEnum::CategoryConcentration)
        ->and(in_array(InsightTypeEnum::CategoryLeadStreak, $types, true))->toBeFalse();
})->with([
    [['food' => '6000', 'other' => '4000'], 5, '2026-08-01', '2026-08-30'],
    [['food' => '6000', 'other' => '4000'], 5, '2026-07-01', '2026-07-31'],
    [['food' => '6000', 'other' => '4000'], 4, '2026-08-01', '2026-08-31'],
    [['food' => '5000', 'other' => '5000'], 5, '2026-08-01', '2026-08-31'],
    [['food' => '4000', 'other' => '6000'], 5, '2026-08-01', '2026-08-31'],
]);

it('requires the exact other threshold for category review', function (string $other, string $food, bool $eligible): void {
    $summary = insightSummary(categories: ['food' => $food, 'other' => $other]);
    $types = insightCandidateTypes(insightRulesCandidates($summary));

    expect(in_array(InsightTypeEnum::CategoryReview, $types, true))->toBe($eligible);
})->with([['4999', '5001', false], ['5000', '5000', true], ['6000', '4000', true]]);

it('distinguishes first expenses recent history and no current records', function (): void {
    $empty = insightSummary(categories: [], count: 0, dates: 0, largest: '0', largestCategory: null);
    $first = insightRulesCandidates($empty, history: false);
    $oldHistory = insightRulesCandidates($empty);
    $recent = insightRulesCandidates(insightSummary(count: 4));

    expect(insightCandidateTypes($first))->toBe([InsightTypeEnum::FirstExpense])
        ->and($first[0]->period())->toBeNull()
        ->and($oldHistory[0]->historyState)->toBe(InsightHistoryStateEnum::NoCurrentExpenses)
        ->and($recent[0]->historyState)->toBe(InsightHistoryStateEnum::CurrentExpenses);
});

it('allows category review beside history guidance but suppresses guidance when financial facts exist', function (): void {
    $summary = insightSummary(categories: ['food' => '4000', 'other' => '6000']);
    $review = insightRulesCandidates($summary);

    expect(insightCandidateTypes($review))->toBe([InsightTypeEnum::CategoryReview, InsightTypeEnum::InsufficientHistory])
        ->and($review[0]->period())->toBeNull()
        ->and($review[1]->historyState)->toBe(InsightHistoryStateEnum::CurrentExpenses);

    $summary = insightSummary(largest: '4000');
    $financial = insightRulesCandidates($summary);
    expect(in_array(InsightTypeEnum::InsufficientHistory, insightCandidateTypes($financial), true))->toBeFalse();
});

it('rejects impossible summaries rather than inventing facts', function (): void {
    insightSummary(count: 2, dates: 3);
})->throws(InvalidInsightAnalysisException::class);

it('rejects candidate facts that do not match their type', function (): void {
    new InsightCandidateValueObject(
        type: InsightTypeEnum::CategoryConcentration,
        analysisPeriod: DatePeriodValueObject::fromDates('2026-10-01', '2026-10-12'),
    );
})->throws(InvalidInsightAnalysisException::class);
