<?php

declare(strict_types=1);

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Ports\UserPort;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Application\UseCases\DeleteUserUseCase;

it('deletes an existing user inside the identity transaction', function (): void {
    $writePort = $this->createMock(TransactionPort::class);
    $repository = $this->createMock(UserRepository::class);
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(10);
    $writePort->expects($this->once())
        ->method('execute')
        ->willReturnCallback(static fn (callable $operation): mixed => $operation());
    $repository->expects($this->once())->method('delete')->with(10)->willReturn(true);

    (new DeleteUserUseCase($userPort, $repository, $writePort))->execute(id: 10);
});

it('fails inside the identity transaction when deleting an absent user', function (): void {
    $writePort = $this->createMock(TransactionPort::class);
    $repository = $this->createMock(UserRepository::class);
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(10);
    $writePort->expects($this->once())
        ->method('execute')
        ->willReturnCallback(static fn (callable $operation): mixed => $operation());
    $repository->expects($this->once())->method('delete')->with(10)->willReturn(false);

    (new DeleteUserUseCase($userPort, $repository, $writePort))->execute(id: 10);
})->throws(UserNotFoundException::class, 'User não encontrado.');

it('does not start a transaction or delete another user', function (): void {
    $writePort = $this->createMock(TransactionPort::class);
    $writePort->expects($this->never())->method('execute');
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(20);
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->never())->method('delete');
    (new DeleteUserUseCase($userPort, $repository, $writePort))->execute(id: 10);
})->throws(UserNotFoundException::class);
