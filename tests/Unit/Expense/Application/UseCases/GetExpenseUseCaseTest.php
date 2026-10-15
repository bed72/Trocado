<?php

declare(strict_types=1);

use App\Core\Application\Ports\UserPort;
use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Expense\Application\Exceptions\ExpenseNotFoundException;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Application\UseCases\GetExpenseUseCase;
use App\Expense\Domain\Entities\ExpenseEntity;
use Tests\Support\Core\Fixtures\UuidFixture;

it('looks up the canonical UUID and authenticated owner explicitly', function (): void {
    $port = $this->createMock(UserPort::class);
    $port->expects($this->once())->method('id')->willReturn(UuidFixture::at(20));
    $expense = new ExpenseEntity(UuidFixture::at(10), UuidFixture::at(20), 100, '2026-09-24');
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->once())->method('getById')->with(UuidFixture::at(10), UuidFixture::at(20))->willReturn($expense);
    expect((new GetExpenseUseCase($port, $repository))->execute(strtoupper(UuidFixture::at(10))))->toBe($expense);
});

it('does not query an invalid UUID outside HTTP', function (): void {
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->never())->method('getById');
    expect(fn () => (new GetExpenseUseCase($this->createMock(UserPort::class), $repository))->execute('42'))->toThrow(InvalidUuidException::class);
});

it('rejects a missing or foreign expense', function (): void {
    $port = $this->createMock(UserPort::class);
    $port->expects($this->once())->method('id')->willReturn(UuidFixture::at(20));
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->once())->method('getById')->with(UuidFixture::at(10), UuidFixture::at(20))->willReturn(null);
    expect(fn () => (new GetExpenseUseCase($port, $repository))->execute(UuidFixture::at(10)))->toThrow(ExpenseNotFoundException::class);
});
