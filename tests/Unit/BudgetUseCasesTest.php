<?php

declare(strict_types=1);

use App\Budget\Application\Exceptions\BudgetNotFoundException;
use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Application\UseCases\CreateBudgetUseCase;
use App\Budget\Application\UseCases\DeleteBudgetUseCase;
use App\Budget\Application\UseCases\GetBudgetUseCase;
use App\Budget\Application\UseCases\ListBudgetsUseCase;
use App\Budget\Application\UseCases\UpdateBudgetUseCase;
use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\Exceptions\InvalidBudgetDateRangeException;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

it('passes a valid domain entity to persistence when creating', function (): void {
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('save')
        ->willReturnCallback(function (BudgetEntity $budget): BudgetEntity {
            expect($budget->id)->toBeNull();
            expect($budget->amount->cents())->toBe(12500);
            expect($budget->startDate)->toBe('2026-09-01');
            expect($budget->endDate)->toBe('2026-09-30');

            return $budget;
        });

    $result = (new CreateBudgetUseCase(repository: $repository))->execute(
        amount: 12500,
        startDate: '2026-09-01',
        endDate: '2026-09-30',
    );

    expect($result->amount->cents())->toBe(12500);
});

it('rejects invalid dates before persisting a new budget', function (): void {
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->never())->method('save');

    (new CreateBudgetUseCase(repository: $repository))->execute(
        amount: 100,
        startDate: '2026-09-30',
        endDate: '2026-09-01',
    );
})->throws(InvalidBudgetDateRangeException::class);

it('throws when the requested budget does not exist', function (): void {
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('findById')->with(42)->willReturn(null);

    (new GetBudgetUseCase(repository: $repository))->execute(id: 42);
})->throws(BudgetNotFoundException::class);

it('lists the entities returned by the repository', function (): void {
    $budget = new BudgetEntity(
        id: 1,
        startDate: '2026-09-01',
        endDate: '2026-09-30',
        amount: MoneyValueObject::fromCents(cents: 100),
    );
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('all')->willReturn([$budget]);

    expect((new ListBudgetsUseCase(budgets: $repository))->execute())->toBe([$budget]);
});

it('preserves fields not supplied when updating a budget', function (): void {
    $current = new BudgetEntity(
        id: 7,
        startDate: '2026-09-01',
        endDate: '2026-09-30',
        amount: MoneyValueObject::fromCents(cents: 12500),
    );
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('findById')->with(7)->willReturn($current);
    $repository->expects($this->once())->method('save')
        ->willReturnCallback(fn (BudgetEntity $budget): BudgetEntity => $budget);

    $result = (new UpdateBudgetUseCase(
        useCase: new GetBudgetUseCase(repository: $repository),
        repository: $repository,
    ))->execute(id: 7, amount: 0, startDate: null, endDate: null);

    expect($result->id)->toBe(7);
    expect($result->amount->cents())->toBe(0);
    expect($result->startDate)->toBe($current->startDate);
    expect($result->endDate)->toBe($current->endDate);
});

it('throws when no budget was deleted', function (): void {
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('delete')->with(42)->willReturn(false);

    (new DeleteBudgetUseCase(repository: $repository))->execute(id: 42);
})->throws(BudgetNotFoundException::class);
