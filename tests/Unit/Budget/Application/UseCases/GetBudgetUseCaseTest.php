<?php

declare(strict_types=1);

use App\Budget\Application\Exceptions\BudgetNotFoundException;
use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Application\UseCases\GetBudgetUseCase;
use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

it('returns the entity found by the repository', function (): void {
    $budget = new BudgetEntity(
        id: 42,
        endDate: '2026-09-30',
        startDate: '2026-09-01',
        amount: MoneyValueObject::fromCents(cents: 12500),
    );
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('findById')->with(42)->willReturn($budget);

    expect((new GetBudgetUseCase(repository: $repository))->execute(id: 42))->toBe($budget);
});

it('throws a descriptive exception when the budget does not exist', function (): void {
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('findById')->with(42)->willReturn(null);

    (new GetBudgetUseCase(repository: $repository))->execute(id: 42);
})->throws(BudgetNotFoundException::class, 'Budget não encontrado.');
