<?php

declare(strict_types=1);

use App\Budget\Application\Exceptions\BudgetNotFoundException;
use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Application\UseCases\DeleteBudgetUseCase;

it('deletes an existing budget', function (): void {
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('delete')->with(42)->willReturn(true);

    (new DeleteBudgetUseCase(repository: $repository))->execute(id: 42);

    expect(true)->toBeTrue();
});

it('throws a descriptive exception when no budget was deleted', function (): void {
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())->method('delete')->with(42)->willReturn(false);

    (new DeleteBudgetUseCase(repository: $repository))->execute(id: 42);
})->throws(BudgetNotFoundException::class, 'Budget não encontrado.');
