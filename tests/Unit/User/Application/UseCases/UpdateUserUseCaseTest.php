<?php

declare(strict_types=1);

use App\User\Application\Exceptions\EmailAlreadyUsedException;
use App\User\Application\Exceptions\UserNotFoundException;
use App\User\Application\Repositories\UserRepository;
use App\User\Application\UseCases\UpdateUserUseCase;
use App\User\Domain\Entities\UserEntity;
use App\User\Domain\Exceptions\InvalidEmailException;
use App\User\Domain\Exceptions\InvalidUserNameException;
use App\User\Domain\ValueObjects\EmailValueObject;

beforeEach(function (): void {
    $this->currentUser = new UserEntity(
        id: 10,
        name: 'Maria Silva',
        email: EmailValueObject::fromString(value: 'maria@example.com'),
        createdAt: new DateTimeImmutable('2026-09-21T10:00:00+00:00'),
        updatedAt: new DateTimeImmutable('2026-09-21T10:00:00+00:00'),
    );
});

it('updates the name while preserving email and persistence data', function (): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->with(10)->willReturn($this->currentUser);
    $repository->expects($this->never())->method('findByEmail');
    $repository->expects($this->once())
        ->method('update')
        ->with($this->callback(function (UserEntity $user): bool {
            expect($user->id)->toBe(10)
                ->and($user->name)->toBe('Maria Souza')
                ->and($user->email)->toBe($this->currentUser->email)
                ->and($user->createdAt)->toBe($this->currentUser->createdAt)
                ->and($user->updatedAt)->toBe($this->currentUser->updatedAt);

            return true;
        }))
        ->willReturnCallback(fn (UserEntity $user): UserEntity => $user);

    $updated = (new UpdateUserUseCase(repository: $repository))->execute(
        id: 10,
        name: '  Maria Souza  ',
        email: null,
    );

    expect($updated->name)->toBe('Maria Souza');
});

it('normalizes a new email while preserving the name', function (): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->willReturn($this->currentUser);
    $repository->expects($this->once())
        ->method('findByEmail')
        ->with($this->callback(fn (EmailValueObject $email): bool => $email->value() === 'nova@example.com'))
        ->willReturn(null);
    $repository->expects($this->once())
        ->method('update')
        ->willReturnCallback(fn (UserEntity $user): UserEntity => $user);

    $updated = (new UpdateUserUseCase(repository: $repository))->execute(
        id: 10,
        name: null,
        email: ' NOVA@EXAMPLE.COM ',
    );

    expect($updated->name)->toBe('Maria Silva')
        ->and($updated->email->value())->toBe('nova@example.com');
});

it('allows another representation of the current canonical email', function (): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->willReturn($this->currentUser);
    $repository->expects($this->never())->method('findByEmail');
    $repository->expects($this->once())
        ->method('update')
        ->willReturnCallback(fn (UserEntity $user): UserEntity => $user);

    $updated = (new UpdateUserUseCase(repository: $repository))->execute(
        id: 10,
        name: null,
        email: ' MARIA@EXAMPLE.COM ',
    );

    expect($updated->email->value())->toBe('maria@example.com');
});

it('rejects an email used by another user without updating', function (): void {
    $otherUser = new UserEntity(
        id: 20,
        name: 'Outra Maria',
        email: EmailValueObject::fromString(value: 'outra@example.com'),
    );
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->willReturn($this->currentUser);
    $repository->expects($this->once())->method('findByEmail')->willReturn($otherUser);
    $repository->expects($this->never())->method('update');

    (new UpdateUserUseCase(repository: $repository))->execute(
        id: 10,
        name: null,
        email: 'outra@example.com',
    );
})->throws(EmailAlreadyUsedException::class, 'O e-mail outra@example.com já está em uso.');

it('does not persist invalid updates', function (?string $name, ?string $email, string $exception): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->willReturn($this->currentUser);
    $repository->expects($this->never())->method('update');

    expect(fn (): UserEntity => (new UpdateUserUseCase(repository: $repository))->execute(
        id: 10,
        name: $name,
        email: $email,
    ))->toThrow($exception);
})->with([
    'empty name' => ['   ', null, InvalidUserNameException::class],
    'too long name' => [str_repeat('a', 256), null, InvalidUserNameException::class],
    'invalid email' => [null, 'invalid', InvalidEmailException::class],
]);

it('fails when the user is absent before updating', function (): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->with(10)->willReturn(null);
    $repository->expects($this->never())->method('update');

    (new UpdateUserUseCase(repository: $repository))->execute(id: 10, name: 'Maria', email: null);
})->throws(UserNotFoundException::class, 'User 10 não encontrado.');

it('fails when the user disappears during updating', function (): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('findById')->willReturn($this->currentUser);
    $repository->expects($this->once())->method('update')->willReturn(null);

    (new UpdateUserUseCase(repository: $repository))->execute(id: 10, name: 'Maria', email: null);
})->throws(UserNotFoundException::class, 'User 10 não encontrado.');
