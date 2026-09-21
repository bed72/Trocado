<?php

declare(strict_types=1);

use App\Budget\Application\Ports\BudgetWritePort;
use App\Budget\Application\Repositories\BudgetRecurrenceRepository;
use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Application\UseCases\CreateBudgetUseCase;
use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\Entities\BudgetRecurrenceEntity;
use App\Budget\Domain\Enums\RecurrenceStatusEnum;
use App\Budget\Domain\Exceptions\InvalidBudgetDateRangeException;
use App\Budget\Domain\Exceptions\InvalidMoneyAmountException;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

beforeEach(function (): void {
    $this->recurrenceRepository = $this->createMock(BudgetRecurrenceRepository::class);
    $this->port = $this->createMock(BudgetWritePort::class);
    $this->port->method('execute')->willReturnCallback(fn (callable $operation): mixed => $operation());
});

it('persists a valid domain entity and returns the repository result', function (): void {
    $persisted = new BudgetEntity(
        id: 10,
        endDate: '2026-09-30',
        startDate: '2026-09-01',
        amount: MoneyValueObject::fromCents(cents: 12500),
    );
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('hasOverlap')->willReturn(false);
    $repository->expects($this->once())
        ->method('create')
        ->with($this->callback(function (BudgetEntity $budget): bool {
            expect($budget->id)->toBeNull()
                ->and($budget->amount->cents())->toBe(12500)
                ->and($budget->startDate)->toBe('2026-09-01')
                ->and($budget->endDate)->toBe('2026-09-30');

            return true;
        }))
        ->willReturn($persisted);

    $result = (new CreateBudgetUseCase(
        port: $this->port,
        budgetRepository: $repository,
        recurrenceRepository: $this->recurrenceRepository,
    ))->execute(
        amount: 12500,
        startDate: '2026-09-01',
        endDate: '2026-09-30',
    );

    expect($result)->toBe($persisted);
});

it('does not persist an invalid date range', function (): void {
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->never())->method('create');

    (new CreateBudgetUseCase(
        port: $this->port,
        budgetRepository: $repository,
        recurrenceRepository: $this->recurrenceRepository,
    ))->execute(
        amount: 100,
        startDate: '2026-09-30',
        endDate: '2026-09-01',
    );
})->throws(InvalidBudgetDateRangeException::class);

it('does not persist a negative amount', function (): void {
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->never())->method('create');

    (new CreateBudgetUseCase(
        port: $this->port,
        budgetRepository: $repository,
        recurrenceRepository: $this->recurrenceRepository,
    ))->execute(
        amount: -1,
        startDate: '2026-09-01',
        endDate: '2026-09-30',
    );
})->throws(InvalidMoneyAmountException::class);

it('creates the recurrence before persisting its initial budget', function (): void {
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('hasOverlap')->willReturn(false);
    $this->recurrenceRepository->expects($this->once())
        ->method('create')
        ->with($this->callback(function (BudgetRecurrenceEntity $recurrence): bool {
            expect($recurrence->amount->cents())->toBe(1000)
                ->and($recurrence->durationInDays)->toBe(7)
                ->and($recurrence->nextStartDate)->toBe('2026-01-08');

            return true;
        }))
        ->willReturn(new BudgetRecurrenceEntity(
            id: 5,
            status: RecurrenceStatusEnum::Active,
            amount: MoneyValueObject::fromCents(cents: 1000),
            durationInDays: 7,
            nextStartDate: '2026-01-08',
        ));
    $repository->expects($this->once())
        ->method('create')
        ->with($this->callback(fn (BudgetEntity $budget): bool => $budget->recurrenceId === 5))
        ->willReturnCallback(fn (BudgetEntity $budget): BudgetEntity => $budget);

    $budget = (new CreateBudgetUseCase(
        port: $this->port,
        budgetRepository: $repository,
        recurrenceRepository: $this->recurrenceRepository,
    ))->execute(
        amount: 1000,
        startDate: '2026-01-01',
        endDate: '2026-01-07',
        recurring: true,
    );

    expect($budget->recurrenceId)->toBe(5);
});
