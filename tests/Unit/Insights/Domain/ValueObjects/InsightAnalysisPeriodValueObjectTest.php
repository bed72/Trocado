<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidDatePeriodException;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Domain\Enums\InsightPeriodModeEnum;
use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use App\Insights\Domain\ValueObjects\InsightAnalysisPeriodValueObject;

it('selects inclusive descriptive and comparison periods from the query date and civil month', function (
    string $queryDate, string $selectedDate, string $to, string $previousFrom, string $previousTo,
    string $twoMonthsFrom, string $twoMonthsTo, ?string $comparisonTo, ?string $previousComparisonTo,
    InsightPeriodModeEnum $mode,
): void {
    $period = new InsightAnalysisPeriodValueObject($queryDate, DatePeriodValueObject::monthContaining($selectedDate));

    expect($period->mode)->toBe($mode)
        ->and($period->currentMonth->from())->toBe(substr($selectedDate, 0, 8).'01')
        ->and($period->currentMonth->to())->toBe($to)
        ->and($period->previousMonth->from())->toBe($previousFrom)
        ->and($period->previousMonth->to())->toBe($previousTo)
        ->and($period->twoMonthsAgo->from())->toBe($twoMonthsFrom)
        ->and($period->twoMonthsAgo->to())->toBe($twoMonthsTo)
        ->and($period->currentComparison?->to())->toBe($comparisonTo)
        ->and($period->previousComparison?->to())->toBe($previousComparisonTo)
        ->and($period->periods())->toHaveCount($comparisonTo === null ? 3 : 5);
})->with([
    'current day 12' => ['2026-10-12', '2026-10-01', '2026-10-12', '2026-09-01', '2026-09-30', '2026-08-01', '2026-08-31', '2026-10-11', '2026-09-11', InsightPeriodModeEnum::Current],
    'current first day' => ['2026-10-01', '2026-10-01', '2026-10-01', '2026-09-01', '2026-09-30', '2026-08-01', '2026-08-31', null, null, InsightPeriodModeEnum::Current],
    'current last day stays partial' => ['2026-10-31', '2026-10-01', '2026-10-31', '2026-09-01', '2026-09-30', '2026-08-01', '2026-08-31', '2026-10-30', '2026-09-30', InsightPeriodModeEnum::Current],
    'short February' => ['2027-03-31', '2027-03-01', '2027-03-31', '2027-02-01', '2027-02-28', '2027-01-01', '2027-01-31', '2027-03-28', '2027-02-28', InsightPeriodModeEnum::Current],
    'leap February caps current comparison' => ['2028-03-31', '2028-03-01', '2028-03-31', '2028-02-01', '2028-02-29', '2028-01-01', '2028-01-31', '2028-03-29', '2028-02-29', InsightPeriodModeEnum::Current],
    'closed 30 versus 31 days' => ['2026-10-12', '2026-09-01', '2026-09-30', '2026-08-01', '2026-08-31', '2026-07-01', '2026-07-31', '2026-09-30', '2026-08-31', InsightPeriodModeEnum::Closed],
    'closed leap February' => ['2026-10-12', '2024-02-01', '2024-02-29', '2024-01-01', '2024-01-31', '2023-12-01', '2023-12-31', '2024-02-29', '2024-01-31', InsightPeriodModeEnum::Closed],
    'closed ordinary February' => ['2026-10-12', '2025-02-01', '2025-02-28', '2025-01-01', '2025-01-31', '2024-12-01', '2024-12-31', '2025-02-28', '2025-01-31', InsightPeriodModeEnum::Closed],
    'century not leap' => ['2026-10-12', '1900-02-01', '1900-02-28', '1900-01-01', '1900-01-31', '1899-12-01', '1899-12-31', '1900-02-28', '1900-01-31', InsightPeriodModeEnum::Closed],
    'century leap' => ['2026-10-12', '2000-02-01', '2000-02-29', '2000-01-01', '2000-01-31', '1999-12-01', '1999-12-31', '2000-02-29', '2000-01-31', InsightPeriodModeEnum::Closed],
    'closed year transition' => ['2026-10-12', '2026-01-01', '2026-01-31', '2025-12-01', '2025-12-31', '2025-11-01', '2025-11-30', '2026-01-31', '2025-12-31', InsightPeriodModeEnum::Closed],
    'first representable month' => ['2026-10-12', '0001-03-01', '0001-03-31', '0001-02-01', '0001-02-28', '0001-01-01', '0001-01-31', '0001-03-31', '0001-02-28', InsightPeriodModeEnum::Closed],
    'upper civil bound' => ['9999-12-31', '9999-12-01', '9999-12-31', '9999-11-01', '9999-11-30', '9999-10-01', '9999-10-31', '9999-12-30', '9999-11-30', InsightPeriodModeEnum::Current],
]);

it('rejects future incomplete and unrepresentable selections outside HTTP', function (string $from, string $to): void {
    new InsightAnalysisPeriodValueObject('2026-10-12', DatePeriodValueObject::fromDates($from, $to));
})->with([
    ['2026-11-01', '2026-11-30'], ['2027-01-01', '2027-01-31'],
    ['0001-01-01', '0001-01-31'], ['0001-02-01', '0001-02-28'],
    ['2026-09-02', '2026-09-30'], ['2026-09-01', '2026-09-29'],
    ['2026-09-01', '2026-10-01'],
])->throws(InvalidInsightAnalysisException::class);

it('rejects a noncanonical or impossible query date', function (string $queryDate): void {
    new InsightAnalysisPeriodValueObject($queryDate, DatePeriodValueObject::monthContaining('2026-09-01'));
})->with(['2026-02-29', '2026-10-32', '2026-1-01', '0000-01-01'])->throws(InvalidDatePeriodException::class);
