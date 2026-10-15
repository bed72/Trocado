<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;
use Tests\Support\Core\Fixtures\UuidFixture;

it('preserves identity value objects and timestamps', function (): void {
    $createdAt = new DateTimeImmutable('2026-09-21T10:00:00+00:00');
    $updatedAt = new DateTimeImmutable('2026-09-21T11:00:00+00:00');
    $name = NameValueObject::fromString(value: 'Maria Silva');
    $email = EmailValueObject::fromString(value: 'maria@example.com');

    $user = new UserEntity(
        id: strtoupper(UuidFixture::at(7)),
        name: $name,
        email: $email,
        createdAt: $createdAt,
        updatedAt: $updatedAt,
    );

    expect($user->id)->toBe(UuidFixture::at(7))
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

    expect($propertyNames)->toBe(['id', 'name', 'email', 'avatar', 'createdAt', 'updatedAt', 'status']);
});

it('preserves explicit absence before persistence', function (): void {
    expect((new UserEntity(null, NameValueObject::fromString('Maria'), EmailValueObject::fromString('maria@example.com')))->id)->toBeNull();
});

it('rejects invalid present identities independently of HTTP', function (string $id): void {
    new UserEntity($id, NameValueObject::fromString('Maria'), EmailValueObject::fromString('maria@example.com'));
})->with([
    'numeric' => '42', 'empty' => '', 'hash' => str_repeat('a', 64),
    'v4' => '017f22e2-79b0-4cc3-98c4-000000000001',
    'nil' => '00000000-0000-0000-0000-000000000000',
    'variant' => '017f22e2-79b0-7cc3-c8c4-000000000001',
    'space' => ' '.UuidFixture::at(7),
])->throws(InvalidUuidException::class);
