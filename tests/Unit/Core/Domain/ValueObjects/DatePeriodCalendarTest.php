<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidDatePeriodException;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;

it('preserves valid civil periods without a duration or future limit', function (string $from, string $to): void {
    $period = DatePeriodValueObject::fromDates(from: $from, to: $to);

    expect($period->from())->toBe($from)
        ->and($period->to())->toBe($to);
})->with([
    'one day' => ['2026-10-09', '2026-10-09'],
    'leap day' => ['2028-02-29', '2028-02-29'],
    'leap century' => ['2000-02-29', '2000-03-01'],
    'multiple years' => ['2020-01-01', '2026-12-31'],
    'future' => ['2099-01-01', '2099-12-31'],
    'full four digit calendar' => ['0001-01-01', '9999-12-31'],
]);

it('rejects invalid civil dates in either endpoint and the explicit month reference', function (string $date): void {
    foreach ([
        fn () => DatePeriodValueObject::fromDates(from: $date, to: '9999-12-31'),
        fn () => DatePeriodValueObject::fromDates(from: '0001-01-01', to: $date),
        fn () => DatePeriodValueObject::monthContaining(referenceDate: $date),
    ] as $create) {
        expect($create)->toThrow(InvalidDatePeriodException::class, 'O período deve conter datas civis válidas em Y-m-d.');
    }
})->with([
    'empty' => '',
    'spaces' => '   ',
    'external whitespace belongs to transport' => ' 2026-10-09 ',
    'internal whitespace' => '2026- 10-09',
    'local date' => '09/10/2026',
    'relative date' => 'today',
    'timestamp' => '2026-10-09T00:00:00Z',
    'time' => '2026-10-09 12:00:00',
    'timezone' => '2026-10-09+00:00',
    'unpadded month' => '2026-1-09',
    'unpadded day' => '2026-10-9',
    'non leap year' => '2027-02-29',
    'non leap century' => '1900-02-29',
    'impossible day' => '2026-02-30',
    'april 31' => '2026-04-31',
    'month zero' => '2026-00-01',
    'month thirteen' => '2026-13-01',
    'day zero' => '2026-10-00',
    'year zero' => '0000-01-01',
    'five digit year' => '10000-01-01',
    'trailing newline' => "2026-10-09\n",
    'null byte' => "2026-10-09\0",
]);

it('rejects an inverted interval instead of swapping endpoints', function (): void {
    DatePeriodValueObject::fromDates(from: '2026-10-31', to: '2026-10-01');
})->throws(InvalidDatePeriodException::class, 'O início do período não pode ser posterior ao fim.');

it('includes both endpoints and excludes neighboring civil dates', function (string $date, bool $included): void {
    $period = DatePeriodValueObject::fromDates(from: '2026-10-01', to: '2026-10-31');

    expect($period->contains($date))->toBe($included);
})->with([
    ['2026-09-30', false],
    ['2026-10-01', true],
    ['2026-10-09', true],
    ['2026-10-31', true],
    ['2026-11-01', false],
]);

it('restricts a single day period to that exact day', function (): void {
    $period = DatePeriodValueObject::fromDates(from: '2026-10-09', to: '2026-10-09');

    expect($period->contains('2026-10-08'))->toBeFalse()
        ->and($period->contains('2026-10-09'))->toBeTrue()
        ->and($period->contains('2026-10-10'))->toBeFalse()
        ->and(fn () => $period->contains('2026-02-30'))->toThrow(InvalidDatePeriodException::class);
});

it('derives the whole month from the explicit reference including dates after it', function (string $reference, string $from, string $to): void {
    $period = DatePeriodValueObject::monthContaining(referenceDate: $reference);

    expect($period->from())->toBe($from)
        ->and($period->to())->toBe($to)
        ->and($period->contains($reference))->toBeTrue()
        ->and($period->equals(DatePeriodValueObject::fromDates(from: $from, to: $to)))->toBeTrue();
})->with([
    'mid october' => ['2026-10-09', '2026-10-01', '2026-10-31'],
    'non leap february' => ['2027-02-09', '2027-02-01', '2027-02-28'],
    'leap february' => ['2028-02-09', '2028-02-01', '2028-02-29'],
    'non leap century' => ['1900-02-09', '1900-02-01', '1900-02-28'],
    'leap century' => ['2000-02-09', '2000-02-01', '2000-02-29'],
    'thirty days' => ['2026-04-09', '2026-04-01', '2026-04-30'],
    'year boundary' => ['2026-12-31', '2026-12-01', '2026-12-31'],
    'earliest month' => ['0001-01-01', '0001-01-01', '0001-01-31'],
    'latest month' => ['9999-12-31', '9999-12-01', '9999-12-31'],
]);

it('compares periods by both endpoints', function (): void {
    $period = DatePeriodValueObject::fromDates(from: '2026-10-01', to: '2026-10-31');

    expect($period->equals(DatePeriodValueObject::fromDates('2026-10-01', '2026-10-31')))->toBeTrue()
        ->and($period->equals(DatePeriodValueObject::fromDates('2026-10-02', '2026-10-31')))->toBeFalse()
        ->and($period->equals(DatePeriodValueObject::fromDates('2026-10-01', '2026-10-30')))->toBeFalse();
});

it('keeps civil periods independent of process timezone', function (): void {
    $originalTimezone = date_default_timezone_get();

    try {
        foreach (['UTC', 'America/Sao_Paulo', 'Pacific/Auckland'] as $timezone) {
            date_default_timezone_set($timezone);

            $period = DatePeriodValueObject::monthContaining('2026-10-31');

            expect($period->from())->toBe('2026-10-01')
                ->and($period->to())->toBe('2026-10-31');
        }
    } finally {
        date_default_timezone_set($originalTimezone);
    }
});
