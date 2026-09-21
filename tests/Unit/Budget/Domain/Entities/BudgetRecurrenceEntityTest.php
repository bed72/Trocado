<?php

declare(strict_types=1);

use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\Entities\BudgetRecurrenceEntity;
use App\Budget\Domain\Enums\RecurrenceStatusEnum;
use App\Budget\Domain\Exceptions\InvalidBudgetRecurrenceException;
use App\Budget\Domain\Exceptions\InvalidRecurrenceTransitionException;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

it('derives an inclusive duration and the next consecutive interval', function (): void {
    $recurrence = BudgetRecurrenceEntity::fromInitialBudget(new BudgetEntity(
        id: null,
        endDate: '2026-01-07',
        startDate: '2026-01-01',
        amount: MoneyValueObject::fromCents(cents: 1000),
    ));

    expect($recurrence->durationInDays)->toBe(7)
        ->and($recurrence->nextStartDate)->toBe('2026-01-08')
        ->and($recurrence->pendingInterval())->toBe([
            'startDate' => '2026-01-08',
            'endDate' => '2026-01-14',
            'nextStartDate' => '2026-01-15',
        ]);
});

it('supports single-day, fixed month-length and leap-day intervals', function (string $startDate, int $duration, array $expected): void {
    $recurrence = new BudgetRecurrenceEntity(
        id: 1,
        nextStartDate: $startDate,
        durationInDays: $duration,
        status: RecurrenceStatusEnum::Active,
        amount: MoneyValueObject::fromCents(cents: 1000),
    );

    expect($recurrence->pendingInterval())->toBe($expected);
})->with([
    'single day' => ['2026-01-08', 1, [
        'startDate' => '2026-01-08',
        'endDate' => '2026-01-08',
        'nextStartDate' => '2026-01-09',
    ]],
    '31 fixed days' => ['2026-02-01', 31, [
        'startDate' => '2026-02-01',
        'endDate' => '2026-03-03',
        'nextStartDate' => '2026-03-04',
    ]],
    'leap day' => ['2028-02-26', 7, [
        'startDate' => '2028-02-26',
        'endDate' => '2028-03-03',
        'nextStartDate' => '2028-03-04',
    ]],
]);

it('validates recurrence dates and duration', function (string $date, int $duration): void {
    new BudgetRecurrenceEntity(
        id: null,
        status: RecurrenceStatusEnum::Active,
        amount: MoneyValueObject::fromCents(cents: 1000),
        durationInDays: $duration,
        nextStartDate: $date,
    );
})->with([
    'zero duration' => ['2026-01-01', 0],
    'negative duration' => ['2026-01-01', -1],
    'invalid date' => ['2026-02-30', 1],
])->throws(InvalidBudgetRecurrenceException::class);

it('rejects durations that exceed the supported calendar range', function (): void {
    new BudgetRecurrenceEntity(
        id: null,
        status: RecurrenceStatusEnum::Active,
        amount: MoneyValueObject::fromCents(cents: 1000),
        durationInDays: 2_000_000,
        nextStartDate: '2026-01-01',
    );
})->throws(InvalidBudgetRecurrenceException::class);

it('rejects an invalid due-date comparison', function (): void {
    activeBudgetRecurrence()->isDue(processingDate: '2026-02-30');
})->throws(InvalidBudgetRecurrenceException::class);

it('supports valid state transitions while preserving its cursor', function (): void {
    $recurrence = activeBudgetRecurrence();
    $blockedAt = new DateTimeImmutable('2026-01-08T00:00:00+00:00');
    $endedAt = new DateTimeImmutable('2026-01-09T00:00:00+00:00');

    $blocked = $recurrence->block(blockedAt: $blockedAt);
    $resumed = $blocked->resume();
    $endedFromActive = $recurrence->end(endedAt: $endedAt);
    $endedFromBlocked = $blocked->end(endedAt: $endedAt);

    expect($blocked->status)->toBe(RecurrenceStatusEnum::Blocked)
        ->and($blocked->blockedAt)->toBe($blockedAt)
        ->and($blocked->nextStartDate)->toBe('2026-01-08')
        ->and($resumed->status)->toBe(RecurrenceStatusEnum::Active)
        ->and($resumed->blockedAt)->toBeNull()
        ->and($resumed->nextStartDate)->toBe('2026-01-08')
        ->and($endedFromActive->status)->toBe(RecurrenceStatusEnum::Ended)
        ->and($endedFromBlocked->status)->toBe(RecurrenceStatusEnum::Ended)
        ->and($endedFromBlocked->endedAt)->toBe($endedAt);
});

it('rejects changes and transitions after ending', function (string $operation): void {
    $ended = activeBudgetRecurrence()->end(new DateTimeImmutable('2026-01-08T00:00:00+00:00'));

    match ($operation) {
        'update' => $ended->updateTemplate(MoneyValueObject::fromCents(cents: 2000), 5),
        'resume' => $ended->resume(),
        'block' => $ended->block(new DateTimeImmutable('2026-01-09T00:00:00+00:00')),
        'end' => $ended->end(new DateTimeImmutable('2026-01-09T00:00:00+00:00')),
        'advance' => $ended->advanceToNextInterval(),
    };
})->with(['update', 'resume', 'block', 'end', 'advance'])
    ->throws(InvalidRecurrenceTransitionException::class);

it('rejects transitions that do not match the current state', function (string $operation): void {
    $active = activeBudgetRecurrence();
    $blocked = $active->block(new DateTimeImmutable('2026-01-08T00:00:00+00:00'));

    match ($operation) {
        'resume active' => $active->resume(),
        'block blocked' => $blocked->block(new DateTimeImmutable('2026-01-09T00:00:00+00:00')),
        'advance blocked' => $blocked->advanceToNextInterval(),
    };
})->with(['resume active', 'block blocked', 'advance blocked'])
    ->throws(InvalidRecurrenceTransitionException::class);

it('updates only the future template and advances one interval', function (): void {
    $recurrence = activeBudgetRecurrence();
    $updated = $recurrence->updateTemplate(
        amount: MoneyValueObject::fromCents(cents: 2500),
        durationInDays: 3,
    );
    $advanced = $updated->advanceToNextInterval();

    expect($updated->amount->cents())->toBe(2500)
        ->and($updated->durationInDays)->toBe(3)
        ->and($updated->nextStartDate)->toBe('2026-01-08')
        ->and($advanced->nextStartDate)->toBe('2026-01-11');
});

function activeBudgetRecurrence(): BudgetRecurrenceEntity
{
    return new BudgetRecurrenceEntity(
        id: 1,
        status: RecurrenceStatusEnum::Active,
        amount: MoneyValueObject::fromCents(cents: 1000),
        durationInDays: 7,
        nextStartDate: '2026-01-08',
    );
}
