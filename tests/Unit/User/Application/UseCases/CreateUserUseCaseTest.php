<?php

declare(strict_types=1);

use App\User\Application\Exceptions\EmailAlreadyUsedException;
use App\User\Application\Repositories\UserRepository;
use App\User\Application\UseCases\CreateUserUseCase;
use App\User\Domain\Entities\UserEntity;
use App\User\Domain\Exceptions\InvalidEmailException;
use App\User\Domain\Exceptions\InvalidUserNameException;
use App\User\Domain\ValueObjects\EmailValueObject;

it('persists a canonical user with the explicit create operation', function (): void {
    $persisted = new UserEntity(
        id: 10,
        name: 'Maria Silva',
        email: EmailValueObject::fromString(value: 'maria.silva@example.com'),
        createdAt: new DateTimeImmutable('2026-09-21T10:00:00+00:00'),
        updatedAt: new DateTimeImmutable('2026-09-21T10:00:00+00:00'),
    );
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())
        ->method('findByEmail')
        ->with($this->callback(fn (EmailValueObject $email): bool => $email->value() === 'maria.silva@example.com'))
        ->willReturn(null);
    $repository->expects($this->once())
        ->method('create')
        ->with($this->callback(function (UserEntity $user): bool {
            expect($user->id)->toBeNull()
                ->and($user->name)->toBe('Maria Silva')
                ->and($user->email->value())->toBe('maria.silva@example.com')
                ->and($user->createdAt)->toBeNull()
                ->and($user->updatedAt)->toBeNull();

            return true;
        }))
        ->willReturn($persisted);

    $result = (new CreateUserUseCase(repository: $repository))->execute(
        name: '  Maria Silva  ',
        email: '  Maria.Silva@Example.COM  ',
    );

    expect($result)->toBe($persisted);
});

it('does not query or persist an invalid user', function (string $name, string $email, string $exception): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->never())->method('findByEmail');
    $repository->expects($this->never())->method('create');

    expect(fn (): UserEntity => (new CreateUserUseCase(repository: $repository))->execute(name: $name, email: $email))
        ->toThrow($exception);
})->with([
    'invalid name' => ['   ', 'maria@example.com', InvalidUserNameException::class],
    'invalid email' => ['Maria Silva', 'invalid', InvalidEmailException::class],
]);

it('rejects a canonical email already in use without persisting', function (): void {
    $existing = new UserEntity(
        id: 1,
        name: 'Maria',
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    );
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())
        ->method('findByEmail')
        ->with($this->callback(fn (EmailValueObject $email): bool => $email->equals($existing->email)))
        ->willReturn($existing);
    $repository->expects($this->never())->method('create');

    (new CreateUserUseCase(repository: $repository))->execute(
        name: 'Outra Maria',
        email: ' MARIA@EXAMPLE.COM ',
    );
})->throws(EmailAlreadyUsedException::class, 'Não foi possível utilizar o e-mail informado.');
