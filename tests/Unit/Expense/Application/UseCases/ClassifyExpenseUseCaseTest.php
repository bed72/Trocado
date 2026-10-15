<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\TransactionPort;
use App\Core\Domain\Enums\ExpenseCategoryEnum;
use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Expense\Application\Data\ApplyExpenseClassificationInput;
use App\Expense\Application\Data\ExpenseClassificationOutput;
use App\Expense\Application\Ports\ExpenseClassificationPort;
use App\Expense\Application\Repositories\ExpenseCategorizationRepository;
use App\Expense\Application\UseCases\ClassifyExpenseUseCase;
use Tests\Support\Core\Fixtures\UuidFixture;

it('applies a valid suggestion only through the pending attempt', function (): void {
    $port = $this->createMock(ExpenseClassificationPort::class);
    $port->expects($this->once())->method('suggest')->with('Mercado - 2 itens')->willReturn(ExpenseCategoryEnum::Food);
    $repository = $this->createMock(ExpenseCategorizationRepository::class);
    $repository->expects($this->once())->method('findClassificationAttempt')
        ->with(UuidFixture::at(10), 'token')->willReturn(new ExpenseClassificationOutput('Mercado - 2 itens'));
    $repository->expects($this->once())->method('applyClassificationAttempt')
        ->with(new ApplyExpenseClassificationInput(UuidFixture::at(10), 'token', 'Mercado - 2 itens', ExpenseCategoryEnum::Food))->willReturn(UuidFixture::at(20));

    (new ClassifyExpenseUseCase(classificationPort: $port, transactionPort: $this->createMock(TransactionPort::class), observabilityPort: $this->createMock(ObservabilityPort::class), repository: $repository))->execute(expenseId: UuidFixture::at(10), token: 'token');
});

it('clears an attempt when the provider returns an invalid suggestion', function (): void {
    $port = $this->createMock(ExpenseClassificationPort::class);
    $port->expects($this->once())->method('suggest')->willReturn(null);
    $repository = $this->createMock(ExpenseCategorizationRepository::class);
    $repository->expects($this->once())->method('findClassificationAttempt')
        ->willReturn(new ExpenseClassificationOutput('Uber 123'));
    $repository->expects($this->once())->method('cancelClassification')->with(UuidFixture::at(10), 'token');

    (new ClassifyExpenseUseCase(classificationPort: $port, transactionPort: $this->createMock(TransactionPort::class), observabilityPort: $this->createMock(ObservabilityPort::class), repository: $repository))->execute(expenseId: UuidFixture::at(10), token: 'token');
});

it('does not call the provider for a cancelled or expired attempt', function (): void {
    $port = $this->createMock(ExpenseClassificationPort::class);
    $port->expects($this->never())->method('suggest');
    $repository = $this->createMock(ExpenseCategorizationRepository::class);
    $repository->expects($this->once())->method('findClassificationAttempt')->with(UuidFixture::at(10), 'token')->willReturn(null);

    (new ClassifyExpenseUseCase(classificationPort: $port, transactionPort: $this->createMock(TransactionPort::class), observabilityPort: $this->createMock(ObservabilityPort::class), repository: $repository))->execute(expenseId: UuidFixture::at(10), token: 'token');
});

it('rejects legacy job identifiers before accessing attempts', function (string $operation): void {
    $repository = $this->createMock(ExpenseCategorizationRepository::class);
    $repository->expects($this->never())->method('findClassificationAttempt');
    $repository->expects($this->never())->method('cancelClassification');
    $port = $this->createMock(ExpenseClassificationPort::class);
    $port->expects($this->never())->method('suggest');
    $useCase = new ClassifyExpenseUseCase($this->createMock(TransactionPort::class), $this->createMock(ObservabilityPort::class), $port, $repository);
    expect(fn () => $useCase->$operation('42', 'token'))->toThrow(InvalidUuidException::class);
})->with(['execute', 'fail']);
