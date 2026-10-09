<?php

declare(strict_types=1);

use App\Core\Domain\ValueObjects\CentsValueObject;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use App\Insights\Domain\ValueObjects\ExpensePeriodSummaryValueObject;

/** @param array<string, string> $categories */
function periodSummaryValueObjectFixture(
    int $count = 5,
    int $dates = 3,
    string $total = '10000',
    string $largest = '4000',
    string $to = '2026-10-12',
    string $from = '2026-10-01',
    ?string $largestCategory = 'food',
    array $categories = ['food' => '6000', 'other' => '4000'],
): ExpensePeriodSummaryValueObject {
    return new ExpensePeriodSummaryValueObject(
        expenseCount: $count,
        distinctDateCount: $dates,
        largestExpenseCategory: $largestCategory,
        period: DatePeriodValueObject::fromDates($from, $to),
        totalAmount: CentsValueObject::fromCents($total),
        largestExpenseAmount: CentsValueObject::fromCents($largest),
        categories: array_map(CentsValueObject::fromCents(...), $categories),
    );
}

it('preserves valid facts and returns the recorded category amounts', function (): void {
    $summary = periodSummaryValueObjectFixture();

    expect($summary->expenseCount)->toBe(5)
        ->and($summary->distinctDateCount)->toBe(3)
        ->and($summary->totalAmount->cents())->toBe('10000')
        ->and($summary->largestExpenseAmount->cents())->toBe('4000')
        ->and($summary->largestExpenseCategory)->toBe('food')
        ->and($summary->period->to())->toBe('2026-10-12')
        ->and($summary->categoryAmount('food'))->toBe($summary->categories['food'])
        ->and($summary->categoryAmount('other')->cents())->toBe('4000')
        ->and($summary->categoryAmount('health')->cents())->toBe('0')
        ->and(array_keys($summary->categories))->toBe(['food', 'other']);
});

it('accepts an empty period without inventing a leading category', function (): void {
    $summary = periodSummaryValueObjectFixture(categories: [], count: 0, dates: 0, total: '0', largest: '0', largestCategory: null);

    expect($summary->uniqueLeadingCategory())->toBeNull()
        ->and($summary->categoryAmount('food')->isZero())->toBeTrue()
        ->and($summary->categories)->toBe([]);
});

it('rejects negative or impossible counts', function (int $count, int $dates): void {
    periodSummaryValueObjectFixture(count: $count, dates: $dates);
})->with([
    'negative expense count' => [-1, 0],
    'negative distinct date count' => [5, -1],
    'more dates than expenses' => [5, 6],
    'more dates than calendar days' => [13, 13],
])->throws(InvalidInsightAnalysisException::class, 'As contagens do período são inconsistentes.');

it('rejects invalid category keys values and zero category totals', function (string $case): void {
    $amount = CentsValueObject::fromCents('10000');
    $categories = match ($case) {
        'empty category' => ['' => $amount],
        'numeric category' => [1 => $amount],
        'raw amount' => ['food' => '10000'],
        'zero amount' => ['food' => $amount, 'other' => CentsValueObject::fromCents('0')],
    };

    new ExpensePeriodSummaryValueObject(
        expenseCount: 5,
        totalAmount: $amount,
        distinctDateCount: 3,
        categories: $categories,
        largestExpenseCategory: 'food',
        largestExpenseAmount: CentsValueObject::fromCents('4000'),
        period: DatePeriodValueObject::fromDates('2026-10-01', '2026-10-12'),
    );
})->with(['empty category', 'numeric category', 'raw amount', 'zero amount'])
    ->throws(InvalidInsightAnalysisException::class, 'A distribuição de categorias é inválida.');

it('requires category amounts to account for the entire period total', function (string $total): void {
    periodSummaryValueObjectFixture(total: $total);
})->with(['9999', '10001'])
    ->throws(InvalidInsightAnalysisException::class, 'As categorias devem representar o total do período.');

it('rejects more categories than recorded expenses', function (): void {
    periodSummaryValueObjectFixture(count: 1, dates: 1);
})->throws(InvalidInsightAnalysisException::class, 'As categorias devem representar o total do período.');

it('rejects largest expense facts on an empty period', function (string $largest, ?string $category): void {
    periodSummaryValueObjectFixture(categories: [], count: 0, dates: 0, total: '0', largest: $largest, largestCategory: $category);
})->with([
    ['1', null],
    ['0', 'food'],
])->throws(InvalidInsightAnalysisException::class, 'Um período vazio não pode conter valores ou categorias.');

it('requires a positive largest expense in an existing category for nonempty periods', function (int $dates, string $largest, ?string $category): void {
    periodSummaryValueObjectFixture(dates: $dates, largest: $largest, largestCategory: $category);
})->with([
    'no recorded dates' => [0, '4000', 'food'],
    'zero largest expense' => [3, '0', 'food'],
    'missing largest category' => [3, '4000', null],
    'category outside the distribution' => [3, '4000', 'health'],
    'largest expense exceeds its category' => [3, '6001', 'food'],
])->throws(InvalidInsightAnalysisException::class, 'O maior lançamento deve pertencer à distribuição do período.');

it('rejects nonempty periods without monetary facts', function (): void {
    periodSummaryValueObjectFixture(categories: [], total: '0', largest: '0', largestCategory: null);
})->throws(InvalidInsightAnalysisException::class);

it('determines unique leadership independently of category order and earlier ties', function (array $categories, ?string $leader): void {
    $summary = periodSummaryValueObjectFixture(categories: $categories, largest: '2000');

    expect($summary->uniqueLeadingCategory())->toBe($leader);
})->with([
    'leader first' => [['food' => '6000', 'other' => '4000'], 'food'],
    'leader last' => [['other' => '4000', 'food' => '6000'], 'food'],
    'top tie' => [['food' => '5000', 'other' => '5000'], null],
    'earlier tie replaced by a greater amount' => [['food' => '2000', 'health' => '2000', 'other' => '6000'], 'other'],
    'top tie after a smaller amount' => [['food' => '2000', 'health' => '4000', 'other' => '4000'], null],
]);

it('preserves exact category totals and rankings beyond native integer precision', function (): void {
    $summary = periodSummaryValueObjectFixture(
        categories: ['food' => '9223372036854775808', 'other' => '9223372036854775809'],
        total: '18446744073709551617',
        largest: '4000000000000000000',
        largestCategory: 'other',
    );

    expect($summary->totalAmount->cents())->toBe('18446744073709551617')
        ->and($summary->uniqueLeadingCategory())->toBe('other')
        ->and($summary->categoryAmount('food')->cents())->toBe('9223372036854775808');
});
