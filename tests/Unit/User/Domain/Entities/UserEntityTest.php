<?php

declare(strict_types=1);

use App\User\Domain\Entities\UserEntity;
use App\User\Domain\Exceptions\InvalidUserNameException;
use App\User\Domain\ValueObjects\EmailValueObject;

it('normalizes the name and preserves identity and timestamps', function (): void {
    $createdAt = new DateTimeImmutable('2026-09-21T10:00:00+00:00');
    $updatedAt = new DateTimeImmutable('2026-09-21T11:00:00+00:00');
    $email = EmailValueObject::fromString(value: 'maria@example.com');

    $user = new UserEntity(
        id: 7,
        name: '  Maria Silva  ',
        email: $email,
        createdAt: $createdAt,
        updatedAt: $updatedAt,
    );

    expect($user->id)->toBe(7)
        ->and($user->name)->toBe('Maria Silva')
        ->and($user->email)->toBe($email)
        ->and($user->createdAt)->toBe($createdAt)
        ->and($user->updatedAt)->toBe($updatedAt);
});

it('rejects an empty normalized name', function (string $name): void {
    new UserEntity(
        id: null,
        name: $name,
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    );
})->with(['', '   '])->throws(InvalidUserNameException::class, 'O nome do usuário não pode ser vazio.');

it('rejects a name above the persistence limit', function (): void {
    new UserEntity(
        id: null,
        name: str_repeat('a', 256),
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    );
})->throws(InvalidUserNameException::class, 'O nome do usuário não pode exceder 255 caracteres.');

it('does not expose authentication or credential state', function (): void {
    $propertyNames = array_map(
        callback: fn (ReflectionProperty $property): string => $property->getName(),
        array: (new ReflectionClass(UserEntity::class))->getProperties(),
    );

    expect($propertyNames)->toBe(['name', 'id', 'email', 'createdAt', 'updatedAt']);
});
