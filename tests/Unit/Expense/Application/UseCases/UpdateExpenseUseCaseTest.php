<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\TransactionPort;
use App\Core\Application\Ports\UserPort;
use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Application\Exceptions\ExpenseNotFoundException;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Application\UseCases\UpdateExpenseUseCase;
use App\Expense\Domain\Entities\ExpenseEntity;
use Tests\Support\Core\Fixtures\UuidFixture;

it('updates an owned expense through the expense repository', function (): void {
    $input = new UpdateExpenseInput(amount: 2500, hasAmount: true);
    $expense = new ExpenseEntity(id: UuidFixture::at(10), userId: UuidFixture::at(20), amount: 2500, occurredOn: '2026-09-24');
    $port = $this->createMock(UserPort::class);
    $port->expects($this->once())->method('id')->willReturn(UuidFixture::at(20));
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->once())->method('update')->with(UuidFixture::at(10), UuidFixture::at(20), $input)->willReturn($expense);

    $updated = (new UpdateExpenseUseCase(userPort: $port, transactionPort: $this->createMock(TransactionPort::class), observabilityPort: $this->createMock(ObservabilityPort::class), repository: $repository))->execute(id: UuidFixture::at(10), input: $input);

    expect($updated)->toBe($expense);
});

it('fails when the expense is absent or owned by another user', function (): void {
    $input = new UpdateExpenseInput(description: 'updated', hasDescription: true);
    $port = $this->createMock(UserPort::class);
    $port->expects($this->once())->method('id')->willReturn(UuidFixture::at(20));
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->once())->method('update')->with(UuidFixture::at(10), UuidFixture::at(20), $input)->willReturn(null);

    (new UpdateExpenseUseCase(userPort: $port, transactionPort: $this->createMock(TransactionPort::class), observabilityPort: $this->createMock(ObservabilityPort::class), repository: $repository))->execute(id: UuidFixture::at(10), input: $input);
})->throws(ExpenseNotFoundException::class, 'Despesa não encontrada.');

it('rejects an invalid UUID before updating outside HTTP', function (): void {
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->never())->method('update');
    $useCase = new UpdateExpenseUseCase($this->createMock(UserPort::class), $this->createMock(TransactionPort::class), $this->createMock(ObservabilityPort::class), $repository);
    expect(fn () => $useCase->execute('42', new UpdateExpenseInput(amount: 1, hasAmount: true)))->toThrow(InvalidUuidException::class);
});
