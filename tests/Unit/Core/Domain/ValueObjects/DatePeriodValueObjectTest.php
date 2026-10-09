<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidDatePeriodException;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;

it('preserves canonical endpoints and counts both boundary days', function (string $from, string $to, int $days): void {
    $period = DatePeriodValueObject::fromDates(from: $from, to: $to);

    expect($period->from())->toBe($from)
        ->and($period->to())->toBe($to)
        ->and($period->days())->toBe($days);
})->with([
    'one day' => ['2026-10-12', '2026-10-12', 1],
    'equivalent eleven day window' => ['2026-10-01', '2026-10-11', 11],
    'non leap february' => ['2027-02-01', '2027-02-28', 28],
    'leap february' => ['2028-02-01', '2028-02-29', 29],
    'leap century' => ['2000-02-28', '2000-03-01', 3],
    'month boundary' => ['2026-09-30', '2026-10-01', 2],
    'year boundary' => ['2026-12-31', '2027-01-01', 2],
    'three period span' => ['2026-08-01', '2026-10-12', 73],
]);

it('rejects impossible and noncanonical dates at either endpoint', function (string $date, string $endpoint): void {
    DatePeriodValueObject::fromDates(
        from: $endpoint === 'from' ? $date : '2026-01-01',
        to: $endpoint === 'to' ? $date : '2028-12-31',
    );
})->with([
    'empty' => '',
    'whitespace' => '   ',
    'non leap february 29' => '2027-02-29',
    'non leap century' => '1900-02-29',
    'april 31' => '2026-04-31',
    'month 13' => '2026-13-01',
    'day zero' => '2026-10-00',
    'unpadded month' => '2026-2-01',
    'unpadded day' => '2026-10-1',
    'datetime' => '2026-10-12T00:00:00Z',
    'surrounding spaces' => ' 2026-10-12 ',
    'relative date' => 'tomorrow',
])->with(['from', 'to'])
    ->throws(InvalidDatePeriodException::class, 'O período deve conter datas civis válidas em Y-m-d.');

it('rejects an end date before the start', function (): void {
    DatePeriodValueObject::fromDates(from: '2026-10-12', to: '2026-10-11');
})->throws(InvalidDatePeriodException::class, 'O início do período não pode ser posterior ao fim.');

it('compares periods by both endpoints rather than their duration', function (): void {
    $period = DatePeriodValueObject::fromDates(from: '2026-10-01', to: '2026-10-11');
    $equal = DatePeriodValueObject::fromDates(from: '2026-10-01', to: '2026-10-11');
    $otherMonth = DatePeriodValueObject::fromDates(from: '2026-09-01', to: '2026-09-11');
    $otherStart = DatePeriodValueObject::fromDates(from: '2026-10-02', to: '2026-10-11');
    $otherEnd = DatePeriodValueObject::fromDates(from: '2026-10-01', to: '2026-10-12');

    expect($period->equals($equal))->toBeTrue()
        ->and($equal->equals($period))->toBeTrue()
        ->and($period->equals($period))->toBeTrue()
        ->and($period->equals($otherMonth))->toBeFalse()
        ->and($period->equals($otherStart))->toBeFalse()
        ->and($period->equals($otherEnd))->toBeFalse();
});

it('compares duration independently of month and endpoint identity', function (string $from, string $to, bool $equivalent): void {
    $period = DatePeriodValueObject::fromDates(from: '2027-03-01', to: '2027-03-28');
    $other = DatePeriodValueObject::fromDates(from: $from, to: $to);

    expect($period->hasSameDurationAs($other))->toBe($equivalent)
        ->and($other->hasSameDurationAs($period))->toBe($equivalent);
})->with([
    'equivalent partial months' => ['2027-02-01', '2027-02-28', true],
    'shifted window' => ['2027-03-02', '2027-03-29', true],
    'longer month' => ['2027-03-01', '2027-03-31', false],
    'leap february' => ['2028-02-01', '2028-02-29', false],
    'single day' => ['2027-03-01', '2027-03-01', false],
]);

it('counts civil days independently of the process timezone and daylight saving', function (): void {
    $originalTimezone = date_default_timezone_get();

    try {
        date_default_timezone_set(timezoneId: 'America/New_York');
        $period = DatePeriodValueObject::fromDates(from: '2026-03-07', to: '2026-03-09');

        expect($period->days())->toBe(3);

        date_default_timezone_set(timezoneId: 'Pacific/Auckland');

        expect($period->days())->toBe(3)
            ->and($period->equals(DatePeriodValueObject::fromDates(from: '2026-03-07', to: '2026-03-09')))->toBeTrue();
    } finally {
        date_default_timezone_set(timezoneId: $originalTimezone);
    }
});

it('identifies month starts and complete calendar months', function (string $from, string $to, bool $startsAtMonthStart, bool $complete): void {
    $period = DatePeriodValueObject::fromDates($from, $to);

    expect($period->startsAtMonthStart())->toBe($startsAtMonthStart)
        ->and($period->isCompleteMonth())->toBe($complete);
})->with([
    'current partial month' => ['2026-10-01', '2026-10-12', true, false],
    'complete thirty day month' => ['2026-09-01', '2026-09-30', true, true],
    'complete thirty one day month' => ['2026-08-01', '2026-08-31', true, true],
    'complete non leap february' => ['2027-02-01', '2027-02-28', true, true],
    'complete leap february' => ['2028-02-01', '2028-02-29', true, true],
    'incomplete leap february' => ['2028-02-01', '2028-02-28', true, false],
    'missing first day' => ['2026-09-02', '2026-09-30', false, false],
    'crosses into the following month' => ['2026-09-01', '2026-10-01', true, false],
]);

it('recognizes the immediately preceding month across years and month lengths', function (string $from, string $to, string $otherFrom, string $otherTo, bool $previous): void {
    $period = DatePeriodValueObject::fromDates($from, $to);
    $other = DatePeriodValueObject::fromDates($otherFrom, $otherTo);

    expect($period->isPreviousMonthOf($other))->toBe($previous);
})->with([
    'consecutive closed and partial months' => ['2026-09-01', '2026-09-30', '2026-10-01', '2026-10-12', true],
    'equivalent comparison windows' => ['2026-09-01', '2026-09-11', '2026-10-01', '2026-10-11', true],
    'year boundary' => ['2026-12-01', '2026-12-31', '2027-01-01', '2027-01-12', true],
    'leap february before march' => ['2028-02-01', '2028-02-29', '2028-03-01', '2028-03-31', true],
    'same month' => ['2026-10-01', '2026-10-11', '2026-10-01', '2026-10-12', false],
    'skipped month' => ['2026-08-01', '2026-08-31', '2026-10-01', '2026-10-12', false],
    'reversed month order' => ['2026-11-01', '2026-11-30', '2026-10-01', '2026-10-12', false],
    'candidate spans more than one month' => ['2026-09-01', '2026-10-01', '2026-10-01', '2026-10-12', false],
]);
