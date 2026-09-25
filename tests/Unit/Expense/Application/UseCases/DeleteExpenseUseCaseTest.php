<?php

declare(strict_types=1);

use App\Expense\Application\Exceptions\ExpenseNotFoundException;
use App\Expense\Application\Ports\UserPort;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Application\UseCases\DeleteExpenseUseCase;

it('deletes an owned expense through the expense repository', function (): void {
    $port = $this->createMock(UserPort::class);
    $port->expects($this->once())->method('id')->willReturn(20);
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->once())->method('deleteByUser')->with(10, 20)->willReturn(true);

    (new DeleteExpenseUseCase($port, $repository))->execute(id: 10);
});

it('fails when the expense is absent or owned by another user', function (): void {
    $port = $this->createMock(UserPort::class);
    $port->expects($this->once())->method('id')->willReturn(20);
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->once())->method('deleteByUser')->with(10, 20)->willReturn(false);

    (new DeleteExpenseUseCase($port, $repository))->execute(id: 10);
})->throws(ExpenseNotFoundException::class, 'Despesa não encontrada.');
