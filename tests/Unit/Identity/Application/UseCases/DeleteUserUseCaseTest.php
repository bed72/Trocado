<?php

declare(strict_types=1);

use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Ports\IdentityWritePort;
use App\Identity\Application\Repositories\IdentityRepository;
use App\Identity\Application\UseCases\DeleteUserUseCase;

it('deletes an existing user inside the identity transaction', function (): void {
    $writePort = $this->createMock(IdentityWritePort::class);
    $repository = $this->createMock(IdentityRepository::class);
    $writePort->expects($this->once())
        ->method('execute')
        ->willReturnCallback(static fn (callable $operation): mixed => $operation());
    $repository->expects($this->once())->method('delete')->with(10)->willReturn(true);

    (new DeleteUserUseCase($writePort, $repository))->execute(id: 10);
});

it('fails inside the identity transaction when deleting an absent user', function (): void {
    $writePort = $this->createMock(IdentityWritePort::class);
    $repository = $this->createMock(IdentityRepository::class);
    $writePort->expects($this->once())
        ->method('execute')
        ->willReturnCallback(static fn (callable $operation): mixed => $operation());
    $repository->expects($this->once())->method('delete')->with(10)->willReturn(false);

    (new DeleteUserUseCase($writePort, $repository))->execute(id: 10);
})->throws(UserNotFoundException::class, 'User não encontrado.');
