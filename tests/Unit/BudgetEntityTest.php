<?php

declare(strict_types=1);

use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\Exceptions\InvalidBudgetDateRangeException;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

it('accepts a single day and a leap day', function (): void {
    $budget = new BudgetEntity(
        id: null,
        startDate: '2024-02-29',
        endDate: '2024-02-29',
        amount: MoneyValueObject::fromCents(cents: 0),
    );

    expect($budget->startDate)->toBe('2024-02-29');
    expect($budget->endDate)->toBe('2024-02-29');
});

it('rejects invalid dates and reversed ranges', function (string $startDate, string $endDate): void {
    new BudgetEntity(
        id: null,
        startDate: $startDate,
        endDate: $endDate,
        amount: MoneyValueObject::fromCents(cents: 100),
    );
})->with([
    'invalid start date' => ['2025-02-29', '2025-03-01'],
    'invalid end date' => ['2025-02-01', '2025-02-30'],
    'invalid format' => ['2025-2-01', '2025-02-28'],
    'reversed range' => ['2025-03-01', '2025-02-28'],
])->throws(InvalidBudgetDateRangeException::class);
