<?php

declare(strict_types=1);

use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;

it('exposes only the explicit persistence operations', function (): void {
    $methodsByName = [];
    $methods = (new ReflectionClass(UserRepository::class))->getMethods();

    foreach ($methods as $method) {
        $methodsByName[$method->getName()] = $method;
    }

    ksort($methodsByName);

    $typeName = static fn (?ReflectionType $type): ?string => $type instanceof ReflectionNamedType ? $type->getName() : null;

    expect(array_keys($methodsByName))->toBe(['create', 'delete', 'getByEmail', 'getById', 'update'])
        ->and($typeName($methodsByName['create']->getParameters()[0]->getType()))->toBe(UserEntity::class)
        ->and($typeName($methodsByName['create']->getParameters()[1]->getType()))->toBe('string')
        ->and($methodsByName['create']->getParameters()[1]->getAttributes(SensitiveParameter::class))->toHaveCount(1)
        ->and($typeName($methodsByName['create']->getReturnType()))->toBe(UserEntity::class)
        ->and($typeName($methodsByName['update']->getParameters()[0]->getType()))->toBe(UserEntity::class)
        ->and($typeName($methodsByName['update']->getReturnType()))->toBe(UserEntity::class)
        ->and($methodsByName['update']->getReturnType()?->allowsNull())->toBeTrue()
        ->and($typeName($methodsByName['delete']->getParameters()[0]->getType()))->toBe('int')
        ->and($typeName($methodsByName['delete']->getReturnType()))->toBe('bool')
        ->and($typeName($methodsByName['getById']->getParameters()[0]->getType()))->toBe('int')
        ->and($typeName($methodsByName['getById']->getReturnType()))->toBe(UserEntity::class)
        ->and($methodsByName['getById']->getReturnType()?->allowsNull())->toBeTrue()
        ->and($typeName($methodsByName['getByEmail']->getParameters()[0]->getType()))->toBe(EmailValueObject::class)
        ->and($typeName($methodsByName['getByEmail']->getReturnType()))->toBe(UserEntity::class)
        ->and($methodsByName['getByEmail']->getReturnType()?->allowsNull())->toBeTrue();
});
