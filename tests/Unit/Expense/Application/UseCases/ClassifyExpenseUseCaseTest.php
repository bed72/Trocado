<?php

declare(strict_types=1);

use App\Expense\Application\Data\ApplyExpenseClassificationInput;
use App\Expense\Application\Data\ExpenseClassificationOutput;
use App\Expense\Application\Ports\ExpenseClassificationPort;
use App\Expense\Application\Repositories\ExpenseCategorizationRepository;
use App\Expense\Application\UseCases\ClassifyExpenseUseCase;
use App\Expense\Domain\Enums\ExpenseCategoryEnum;

it('applies a valid suggestion only through the pending attempt', function (): void {
    $port = $this->createMock(ExpenseClassificationPort::class);
    $port->expects($this->once())->method('suggest')->with('Mercado - 2 itens')->willReturn(ExpenseCategoryEnum::Food);
    $repository = $this->createMock(ExpenseCategorizationRepository::class);
    $repository->expects($this->once())->method('findClassificationAttempt')
        ->with(10, 'token')->willReturn(new ExpenseClassificationOutput('Mercado - 2 itens'));
    $repository->expects($this->once())->method('applyClassificationAttempt')
        ->with(new ApplyExpenseClassificationInput(10, 'token', 'Mercado - 2 itens', ExpenseCategoryEnum::Food))->willReturn(20);

    (new ClassifyExpenseUseCase(port: $port, repository: $repository))->execute(expenseId: 10, token: 'token');
});

it('clears an attempt when the provider returns an invalid suggestion', function (): void {
    $port = $this->createMock(ExpenseClassificationPort::class);
    $port->expects($this->once())->method('suggest')->willReturn(null);
    $repository = $this->createMock(ExpenseCategorizationRepository::class);
    $repository->expects($this->once())->method('findClassificationAttempt')
        ->willReturn(new ExpenseClassificationOutput('Uber 123'));
    $repository->expects($this->once())->method('cancelClassification')->with(10, 'token');

    (new ClassifyExpenseUseCase(port: $port, repository: $repository))->execute(expenseId: 10, token: 'token');
});

it('does not call the provider for a cancelled or expired attempt', function (): void {
    $port = $this->createMock(ExpenseClassificationPort::class);
    $port->expects($this->never())->method('suggest');
    $repository = $this->createMock(ExpenseCategorizationRepository::class);
    $repository->expects($this->once())->method('findClassificationAttempt')->with(10, 'token')->willReturn(null);

    (new ClassifyExpenseUseCase(port: $port, repository: $repository))->execute(expenseId: 10, token: 'token');
});
