<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\UserPort;
use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Application\UseCases\UpdateUserUseCase;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\Exceptions\InvalidNameException;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;

$createCurrentUser = fn (): UserEntity => new UserEntity(
    id: 10,
    name: NameValueObject::fromString(value: 'Maria Silva'),
    createdAt: new DateTimeImmutable('2026-09-21T10:00:00+00:00'),
    updatedAt: new DateTimeImmutable('2026-09-21T10:00:00+00:00'),
    email: EmailValueObject::fromString(value: 'maria@example.com'),
);

it('updates only the name while preserving email and persistence data', function () use ($createCurrentUser): void {
    $port = $this->createMock(ObservabilityPort::class);
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(10);
    $currentUser = $createCurrentUser();
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('getById')->with(10)->willReturn($currentUser);
    $repository->expects($this->once())
        ->method('update')
        ->with($this->callback(function (UserEntity $user) use ($currentUser): bool {
            expect($user->id)->toBe(10)
                ->and($user->name->value())->toBe('Maria Souza')
                ->and($user->email)->toBe($currentUser->email)
                ->and($user->createdAt)->toBe($currentUser->createdAt)
                ->and($user->updatedAt)->toBe($currentUser->updatedAt);

            return true;
        }))
        ->willReturnCallback(fn (UserEntity $user): UserEntity => $user);

    $updated = (new UpdateUserUseCase(userPort: $userPort, observabilityPort: $port, repository: $repository))->execute(
        id: 10,
        name: '  Maria Souza  ',
    );

    expect($updated->name->value())->toBe('Maria Souza');
});

it('does not persist invalid names', function (string $name) use ($createCurrentUser): void {
    $port = $this->createMock(ObservabilityPort::class);
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(10);
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('getById')->willReturn($createCurrentUser());
    $repository->expects($this->never())->method('update');

    (new UpdateUserUseCase(userPort: $userPort, observabilityPort: $port, repository: $repository))->execute(
        id: 10,
        name: $name,
    );
})->with(['   ', str_repeat('a', 13)])->throws(InvalidNameException::class);

it('fails when the user is absent before updating', function (): void {
    $port = $this->createMock(ObservabilityPort::class);
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(10);
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('getById')->with(10)->willReturn(null);
    $repository->expects($this->never())->method('update');

    (new UpdateUserUseCase(userPort: $userPort, observabilityPort: $port, repository: $repository))->execute(id: 10, name: 'Maria');
})->throws(UserNotFoundException::class, 'User não encontrado.');

it('fails when the user disappears during updating', function () use ($createCurrentUser): void {
    $port = $this->createMock(ObservabilityPort::class);
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(10);
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('getById')->willReturn($createCurrentUser());
    $repository->expects($this->once())->method('update')->willReturn(null);

    (new UpdateUserUseCase(userPort: $userPort, observabilityPort: $port, repository: $repository))->execute(id: 10, name: 'Maria');
})->throws(UserNotFoundException::class, 'User não encontrado.');

it('does not read or write another user', function (): void {
    $observabilityPort = $this->createMock(ObservabilityPort::class);
    $port = $this->createMock(UserPort::class);
    $port->method('id')->willReturn(20);
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->never())->method('getById');
    $repository->expects($this->never())->method('update');

    (new UpdateUserUseCase(userPort: $port, observabilityPort: $observabilityPort, repository: $repository))->execute(id: 10, name: 'Maria');
})->throws(UserNotFoundException::class);
