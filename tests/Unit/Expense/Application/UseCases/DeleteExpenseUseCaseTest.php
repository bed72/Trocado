<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\TransactionPort;
use App\Core\Application\Ports\UserPort;
use App\Expense\Application\Exceptions\ExpenseNotFoundException;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Application\UseCases\DeleteExpenseUseCase;

it('deletes an owned expense through the expense repository', function (): void {
    $port = $this->createMock(UserPort::class);
    $port->expects($this->once())->method('id')->willReturn(20);
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->once())->method('delete')->with(10, 20)->willReturn(true);

    (new DeleteExpenseUseCase(userPort: $port, transactionPort: $this->createMock(TransactionPort::class), observabilityPort: $this->createMock(ObservabilityPort::class), repository: $repository))->execute(id: 10);
});

it('fails when the expense is absent or owned by another user', function (): void {
    $port = $this->createMock(UserPort::class);
    $port->expects($this->once())->method('id')->willReturn(20);
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->once())->method('delete')->with(10, 20)->willReturn(false);

    (new DeleteExpenseUseCase(userPort: $port, transactionPort: $this->createMock(TransactionPort::class), observabilityPort: $this->createMock(ObservabilityPort::class), repository: $repository))->execute(id: 10);
})->throws(ExpenseNotFoundException::class, 'Despesa não encontrada.');
