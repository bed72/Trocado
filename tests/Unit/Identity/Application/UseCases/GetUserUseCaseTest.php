<?php

declare(strict_types=1);

use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Repositories\IdentityRepository;
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
    $repository = $this->createMock(IdentityRepository::class);
    $repository->expects($this->once())->method('findById')->with(42)->willReturn($user);

    expect((new GetUserUseCase(repository: $repository))->execute(id: 42))->toBe($user);
});

it('throws an application exception when the identifier is absent', function (): void {
    $repository = $this->createMock(IdentityRepository::class);
    $repository->expects($this->once())->method('findById')->with(42)->willReturn(null);

    (new GetUserUseCase(repository: $repository))->execute(id: 42);
})->throws(UserNotFoundException::class, 'User não encontrado.');
