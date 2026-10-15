<?php

declare(strict_types=1);

use App\Core\Application\Ports\UserPort;
use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Application\UseCases\GetUserUseCase;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;
use Tests\Support\Core\Fixtures\UuidFixture;

it('returns the user found by identifier', function (): void {
    $user = new UserEntity(
        id: UuidFixture::at(42),
        name: NameValueObject::fromString(value: 'Maria'),
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    );
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('getById')->with(UuidFixture::at(42))->willReturn($user);

    $port = $this->createMock(UserPort::class);
    $port->method('id')->willReturn(UuidFixture::at(42));
    expect((new GetUserUseCase(port: $port, repository: $repository))->execute(id: strtoupper(UuidFixture::at(42))))->toBe($user);
});

it('throws an application exception when the identifier is absent', function (): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('getById')->with(UuidFixture::at(42))->willReturn(null);

    $port = $this->createMock(UserPort::class);
    $port->method('id')->willReturn(UuidFixture::at(42));
    (new GetUserUseCase(port: $port, repository: $repository))->execute(id: UuidFixture::at(42));
})->throws(UserNotFoundException::class, 'User não encontrado.');

it('does not consult another user', function (): void {
    $port = $this->createMock(UserPort::class);
    $port->method('id')->willReturn(UuidFixture::at(10));
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->never())->method('getById');
    (new GetUserUseCase($port, $repository))->execute(id: UuidFixture::at(42));
})->throws(UserNotFoundException::class);
