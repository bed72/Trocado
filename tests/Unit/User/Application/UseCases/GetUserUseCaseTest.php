<?php

declare(strict_types=1);

use App\User\Application\Exceptions\UserNotFoundException;
use App\User\Application\Repositories\UserRepository;
use App\User\Application\UseCases\GetUserUseCase;
use App\User\Domain\Entities\UserEntity;
use App\User\Domain\ValueObjects\EmailValueObject;

it('returns the user found by identifier', function (): void {
    $user = new UserEntity(
        id: 42,
        name: 'Maria',
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    );
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->with(42)->willReturn($user);

    expect((new GetUserUseCase(repository: $repository))->execute(id: 42))->toBe($user);
});

it('throws an application exception when the identifier is absent', function (): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->with(42)->willReturn(null);

    (new GetUserUseCase(repository: $repository))->execute(id: 42);
})->throws(UserNotFoundException::class, 'User 42 não encontrado.');
