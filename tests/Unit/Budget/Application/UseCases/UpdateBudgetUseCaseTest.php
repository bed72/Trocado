<?php

declare(strict_types=1);

use App\Budget\Application\Exceptions\BudgetNotFoundException;
use App\Budget\Application\Ports\BudgetWritePort;
use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Application\UseCases\GetBudgetUseCase;
use App\Budget\Application\UseCases\UpdateBudgetUseCase;
use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\Exceptions\InvalidBudgetDateRangeException;
use App\Budget\Domain\Exceptions\InvalidMoneyAmountException;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

beforeEach(function (): void {
    $this->port = $this->createMock(BudgetWritePort::class);
    $this->port->method('execute')->willReturnCallback(fn (callable $operation): mixed => $operation());
});

it('updates the amount while preserving dates and timestamps', function (): void {
    $createdAt = new DateTimeImmutable('2026-09-01T10:00:00+00:00');
    $updatedAt = new DateTimeImmutable('2026-09-02T10:00:00+00:00');
    $current = new BudgetEntity(
        id: 7,
        endDate: '2026-09-30',
        createdAt: $createdAt,
        updatedAt: $updatedAt,
        startDate: '2026-09-01',
        amount: MoneyValueObject::fromCents(cents: 12500),
    );
    $persisted = new BudgetEntity(
        id: 7,
        endDate: '2026-09-30',
        createdAt: $createdAt,
        updatedAt: $updatedAt,
        startDate: '2026-09-01',
        amount: MoneyValueObject::fromCents(cents: 0),
    );
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('findById')->with(7)->willReturn($current);
    $repository->expects($this->once())->method('hasOverlap')->with('2026-09-01', '2026-09-30', 7)->willReturn(false);
    $repository->expects($this->once())
        ->method('create')
        ->with($this->callback(function (BudgetEntity $budget) use ($createdAt, $updatedAt): bool {
            expect($budget->id)->toBe(7)
                ->and($budget->amount->cents())->toBe(0)
                ->and($budget->startDate)->toBe('2026-09-01')
                ->and($budget->endDate)->toBe('2026-09-30')
                ->and($budget->createdAt)->toBe($createdAt)
                ->and($budget->updatedAt)->toBe($updatedAt);

            return true;
        }))
        ->willReturn($persisted);

    $result = (new UpdateBudgetUseCase(
        port: $this->port,
        repository: $repository,
        useCase: new GetBudgetUseCase(repository: $repository),
    ))->execute(id: 7, amount: 0, startDate: null, endDate: null);

    expect($result)->toBe($persisted);
});

it('updates dates while preserving the amount', function (): void {
    $current = new BudgetEntity(
        id: 7,
        endDate: '2026-09-30',
        startDate: '2026-09-01',
        amount: MoneyValueObject::fromCents(cents: 12500),
    );
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('findById')->with(7)->willReturn($current);
    $repository->expects($this->once())->method('hasOverlap')->with('2026-10-01', '2026-10-31', 7)->willReturn(false);
    $repository->expects($this->once())->method('create')
        ->willReturnCallback(fn (BudgetEntity $budget): BudgetEntity => $budget);

    $result = (new UpdateBudgetUseCase(
        useCase: new GetBudgetUseCase(repository: $repository),
        port: $this->port,
        repository: $repository,
    ))->execute(id: 7, amount: null, startDate: '2026-10-01', endDate: '2026-10-31');

    expect($result->amount)->toBe($current->amount)
        ->and($result->startDate)->toBe('2026-10-01')
        ->and($result->endDate)->toBe('2026-10-31');
});

it('does not persist when the budget does not exist', function (): void {
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('findById')->with(42)->willReturn(null);
    $repository->expects($this->never())->method('create');

    (new UpdateBudgetUseCase(
        port: $this->port,
        repository: $repository,
        useCase: new GetBudgetUseCase(repository: $repository),
    ))->execute(id: 42, amount: 100, startDate: null, endDate: null);
})->throws(BudgetNotFoundException::class);

it('does not persist an invalid resulting date range', function (): void {
    $current = new BudgetEntity(
        id: 7,
        endDate: '2026-09-30',
        startDate: '2026-09-01',
        amount: MoneyValueObject::fromCents(cents: 12500),
    );
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('findById')->with(7)->willReturn($current);
    $repository->expects($this->never())->method('create');

    (new UpdateBudgetUseCase(
        port: $this->port,
        repository: $repository,
        useCase: new GetBudgetUseCase(repository: $repository),
    ))->execute(id: 7, amount: null, startDate: null, endDate: '2026-08-31');
})->throws(InvalidBudgetDateRangeException::class);

it('does not persist a negative amount', function (): void {
    $current = new BudgetEntity(
        id: 7,
        endDate: '2026-09-30',
        startDate: '2026-09-01',
        amount: MoneyValueObject::fromCents(cents: 12500),
    );
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('findById')->with(7)->willReturn($current);
    $repository->expects($this->never())->method('create');

    (new UpdateBudgetUseCase(
        port: $this->port,
        useCase: new GetBudgetUseCase(repository: $repository),
        repository: $repository,
    ))->execute(id: 7, amount: -1, startDate: null, endDate: null);
})->throws(InvalidMoneyAmountException::class);
