<?php

declare(strict_types=1);

use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Ports\UserPort;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Application\UseCases\GetUserUseCase;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;

it('returns the user found by identifier', function (): void {
    $user = new UserEntity(
        id: 42,
        name: NameValueObject::fromString(value: 'Maria'),
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    );
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->with(42)->willReturn($user);

    $port = $this->createMock(UserPort::class);
    $port->method('id')->willReturn(42);
    expect((new GetUserUseCase(port: $port, repository: $repository))->execute(id: 42))->toBe($user);
});

it('throws an application exception when the identifier is absent', function (): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->with(42)->willReturn(null);

    $port = $this->createMock(UserPort::class);
    $port->method('id')->willReturn(42);
    (new GetUserUseCase(port: $port, repository: $repository))->execute(id: 42);
})->throws(UserNotFoundException::class, 'User não encontrado.');

it('does not consult another user', function (): void {
    $port = $this->createMock(UserPort::class);
    $port->method('id')->willReturn(10);
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->never())->method('findById');
    (new GetUserUseCase($port, $repository))->execute(id: 42);
})->throws(UserNotFoundException::class);
