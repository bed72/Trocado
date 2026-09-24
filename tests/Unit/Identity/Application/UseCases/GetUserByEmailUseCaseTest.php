<?php

declare(strict_types=1);

use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Application\UseCases\GetUserByEmailUseCase;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;

it('normalizes the email and returns the matching user', function (): void {
    $user = new UserEntity(
        id: 42,
        name: NameValueObject::fromString(value: 'Maria'),
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    );
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())
        ->method('findByEmail')
        ->with($this->callback(fn (EmailValueObject $email): bool => $email->equals($user->email)))
        ->willReturn($user);

    $result = (new GetUserByEmailUseCase(repository: $repository))->execute(email: ' Maria@Example.COM ');

    expect($result)->toBe($user);
});

it('throws an application exception when the canonical email is absent', function (): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findByEmail')->willReturn(null);

    (new GetUserByEmailUseCase(repository: $repository))->execute(email: ' Maria@Example.COM ');
})->throws(UserNotFoundException::class, 'User não encontrado.');
