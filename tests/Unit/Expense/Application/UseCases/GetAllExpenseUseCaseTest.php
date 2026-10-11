<?php

declare(strict_types=1);

use App\Core\Application\Ports\UserPort;
use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Data\GetAllExpenseInput;
use App\Expense\Application\Exceptions\InvalidExpenseCursorException;
use App\Expense\Application\Ports\ExpenseQueryCursorPort;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Application\UseCases\GetAllExpenseUseCase;

it('lists expenses with the authenticated owner and explicit optional period', function (bool $filtered): void {
    $input = $filtered
        ? new GetAllExpenseInput(size: 6, cursor: 'opaque-cursor', from: '2026-10-01', to: '2026-10-31', categories: ['food', 'transport'], amountMin: 0, amountMax: 30000, sorts: ['-occurred_on', 'amount'])
        : new GetAllExpenseInput(size: 6, cursor: 'opaque-cursor');
    $output = new ExpensePageOutput(items: [], nextCursor: null, previousCursor: null);
    $port = $this->createMock(UserPort::class);
    $port->expects($this->once())->method('id')->willReturn(20);
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->once())->method('getAll')->with(20, $input)->willReturn($output);
    $cursorPort = $this->createMock(ExpenseQueryCursorPort::class);
    $cursorPort->expects($this->once())->method('decode')->with($input)->willReturn(null);
    $useCase = new GetAllExpenseUseCase(userPort: $port, cursorPort: $cursorPort, repository: $repository);

    $actual = $useCase->execute($input);

    expect($actual)->toBe($output);
})->with(['without filters' => false, 'with a period' => true]);

it('rejects an incompatible cursor before accessing the repository', function (): void {
    $input = new GetAllExpenseInput(cursor: 'invalid');
    $cursorPort = $this->createMock(ExpenseQueryCursorPort::class);
    $cursorPort->expects($this->once())->method('decode')->with($input)->willThrowException(new InvalidExpenseCursorException);
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->never())->method('getAll');
    $useCase = new GetAllExpenseUseCase($this->createMock(UserPort::class), $cursorPort, $repository);
    expect(fn () => $useCase->execute($input))->toThrow(InvalidExpenseCursorException::class);
});
