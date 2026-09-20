<?php

declare(strict_types=1);

use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\Exceptions\InvalidBudgetDateRangeException;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

it('preserves its data for a valid date range', function (): void {
    $createdAt = new DateTimeImmutable('2026-09-01T10:00:00+00:00');
    $updatedAt = new DateTimeImmutable('2026-09-02T10:00:00+00:00');
    $amount = MoneyValueObject::fromCents(cents: 12500);

    $budget = new BudgetEntity(
        id: 7,
        endDate: '2026-09-30',
        startDate: '2026-09-01',
        amount: $amount,
        createdAt: $createdAt,
        updatedAt: $updatedAt,
    );

    expect($budget->id)->toBe(7)
        ->and($budget->startDate)->toBe('2026-09-01')
        ->and($budget->endDate)->toBe('2026-09-30')
        ->and($budget->amount)->toBe($amount)
        ->and($budget->createdAt)->toBe($createdAt)
        ->and($budget->updatedAt)->toBe($updatedAt);
});

it('accepts a single leap day', function (): void {
    $budget = new BudgetEntity(
        id: null,
        endDate: '2024-02-29',
        startDate: '2024-02-29',
        amount: MoneyValueObject::fromCents(cents: 0),
    );

    expect($budget->startDate)->toBe('2024-02-29')
        ->and($budget->endDate)->toBe('2024-02-29');
});

it('rejects invalid dates and reversed ranges', function (string $startDate, string $endDate): void {
    new BudgetEntity(
        id: null,
        endDate: $endDate,
        startDate: $startDate,
        amount: MoneyValueObject::fromCents(cents: 100),
    );
})->with([
    'invalid start date' => ['2025-02-29', '2025-03-01'],
    'invalid end date' => ['2025-02-01', '2025-02-30'],
    'non padded date' => ['2025-2-01', '2025-02-28'],
    'date with time' => ['2025-02-01T00:00:00Z', '2025-02-28'],
    'reversed range' => ['2025-03-01', '2025-02-28'],
])->throws(InvalidBudgetDateRangeException::class);
