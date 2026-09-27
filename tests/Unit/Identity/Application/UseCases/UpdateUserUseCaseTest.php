<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Ports\UserPort;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Application\UseCases\UpdateUserUseCase;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\Exceptions\InvalidNameException;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;

beforeEach(function (): void {
    $this->port = $this->createMock(ObservabilityPort::class);
    $this->userPort = $this->createMock(UserPort::class);
    $this->userPort->method('id')->willReturn(10);
    $this->currentUser = new UserEntity(
        id: 10,
        name: NameValueObject::fromString(value: 'Maria Silva'),
        createdAt: new DateTimeImmutable('2026-09-21T10:00:00+00:00'),
        updatedAt: new DateTimeImmutable('2026-09-21T10:00:00+00:00'),
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    );
});

it('updates only the name while preserving email and persistence data', function (): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->with(10)->willReturn($this->currentUser);
    $repository->expects($this->once())
        ->method('update')
        ->with($this->callback(function (UserEntity $user): bool {
            expect($user->id)->toBe(10)
                ->and($user->name->value())->toBe('Maria Souza')
                ->and($user->email)->toBe($this->currentUser->email)
                ->and($user->createdAt)->toBe($this->currentUser->createdAt)
                ->and($user->updatedAt)->toBe($this->currentUser->updatedAt);

            return true;
        }))
        ->willReturnCallback(fn (UserEntity $user): UserEntity => $user);

    $updated = (new UpdateUserUseCase(userPort: $this->userPort, observabilityPort: $this->port, repository: $repository))->execute(
        id: 10,
        name: '  Maria Souza  ',
    );

    expect($updated->name->value())->toBe('Maria Souza');
});

it('does not persist invalid names', function (string $name): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->willReturn($this->currentUser);
    $repository->expects($this->never())->method('update');

    (new UpdateUserUseCase(userPort: $this->userPort, observabilityPort: $this->port, repository: $repository))->execute(
        id: 10,
        name: $name,
    );
})->with(['   ', str_repeat('a', 13)])->throws(InvalidNameException::class);

it('fails when the user is absent before updating', function (): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->with(10)->willReturn(null);
    $repository->expects($this->never())->method('update');

    (new UpdateUserUseCase(userPort: $this->userPort, observabilityPort: $this->port, repository: $repository))->execute(id: 10, name: 'Maria');
})->throws(UserNotFoundException::class, 'User não encontrado.');

it('fails when the user disappears during updating', function (): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->willReturn($this->currentUser);
    $repository->expects($this->once())->method('update')->willReturn(null);

    (new UpdateUserUseCase(userPort: $this->userPort, observabilityPort: $this->port, repository: $repository))->execute(id: 10, name: 'Maria');
})->throws(UserNotFoundException::class, 'User não encontrado.');

it('does not read or write another user', function (): void {
    $port = $this->createMock(UserPort::class);
    $port->method('id')->willReturn(20);
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->never())->method('findById');
    $repository->expects($this->never())->method('update');

    (new UpdateUserUseCase(userPort: $port, observabilityPort: $this->port, repository: $repository))->execute(id: 10, name: 'Maria');
})->throws(UserNotFoundException::class);
