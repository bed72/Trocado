<?php

declare(strict_types=1);

use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Application\UseCases\GetAllBudgetsUseCase;
use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

it('returns every entity provided by the repository', function (): void {
    $budgets = [new BudgetEntity(
        id: 1,
        endDate: '2026-09-30',
        startDate: '2026-09-01',
        amount: MoneyValueObject::fromCents(cents: 100),
    )];
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('all')->willReturn($budgets);

    expect((new GetAllBudgetsUseCase(budgets: $repository))->execute())->toBe($budgets);
});

it('returns an empty list from an empty repository', function (): void {
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('all')->willReturn([]);

    expect((new GetAllBudgetsUseCase(budgets: $repository))->execute())->toBe([]);
});
