<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\TransactionPort;
use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Application\Exceptions\ExpenseNotFoundException;
use App\Expense\Application\Ports\UserPort;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Application\UseCases\UpdateExpenseUseCase;
use App\Expense\Domain\Entities\ExpenseEntity;

it('updates an owned expense through the expense repository', function (): void {
    $input = new UpdateExpenseInput(amount: 2500, hasAmount: true);
    $expense = new ExpenseEntity(id: 10, userId: 20, amount: 2500, occurredOn: '2026-09-24');
    $port = $this->createMock(UserPort::class);
    $port->expects($this->once())->method('id')->willReturn(20);
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->once())->method('updateByUser')->with(10, 20, $input)->willReturn($expense);

    $updated = (new UpdateExpenseUseCase(userPort: $port, transactionPort: $this->createMock(TransactionPort::class), observabilityPort: $this->createMock(ObservabilityPort::class), repository: $repository))->execute(id: 10, input: $input);

    expect($updated)->toBe($expense);
});

it('fails when the expense is absent or owned by another user', function (): void {
    $input = new UpdateExpenseInput(description: 'updated', hasDescription: true);
    $port = $this->createMock(UserPort::class);
    $port->expects($this->once())->method('id')->willReturn(20);
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->once())->method('updateByUser')->with(10, 20, $input)->willReturn(null);

    (new UpdateExpenseUseCase(userPort: $port, transactionPort: $this->createMock(TransactionPort::class), observabilityPort: $this->createMock(ObservabilityPort::class), repository: $repository))->execute(id: 10, input: $input);
})->throws(ExpenseNotFoundException::class, 'Despesa não encontrada.');
