<?php

declare(strict_types=1);

use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;

it('preserves identity value objects and timestamps', function (): void {
    $createdAt = new DateTimeImmutable('2026-09-21T10:00:00+00:00');
    $updatedAt = new DateTimeImmutable('2026-09-21T11:00:00+00:00');
    $name = NameValueObject::fromString(value: 'Maria Silva');
    $email = EmailValueObject::fromString(value: 'maria@example.com');

    $user = new UserEntity(
        id: 7,
        name: $name,
        email: $email,
        createdAt: $createdAt,
        updatedAt: $updatedAt,
    );

    expect($user->id)->toBe(7)
        ->and($user->name)->toBe($name)
        ->and($user->email)->toBe($email)
        ->and($user->createdAt)->toBe($createdAt)
        ->and($user->updatedAt)->toBe($updatedAt);
});

it('does not expose authentication or credential state', function (): void {
    $propertyNames = array_map(
        array: (new ReflectionClass(UserEntity::class))->getProperties(),
        callback: fn (ReflectionProperty $property): string => $property->getName(),
    );

    expect($propertyNames)->toBe(['id', 'name', 'email', 'createdAt', 'updatedAt']);
});
