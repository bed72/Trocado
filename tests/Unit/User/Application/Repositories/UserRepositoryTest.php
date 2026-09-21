<?php

declare(strict_types=1);

use App\User\Application\Repositories\UserRepository;
use App\User\Domain\Entities\UserEntity;
use App\User\Domain\ValueObjects\EmailValueObject;

it('exposes only the explicit persistence operations', function (): void {
    $methods = (new ReflectionClass(UserRepository::class))->getMethods();
    $methodsByName = [];

    foreach ($methods as $method) {
        $methodsByName[$method->getName()] = $method;
    }

    ksort($methodsByName);

    expect(array_keys($methodsByName))->toBe(['all', 'create', 'delete', 'findByEmail', 'findById', 'update'])
        ->and($methodsByName['create']->getParameters()[0]->getType()?->getName())->toBe(UserEntity::class)
        ->and($methodsByName['create']->getReturnType()?->getName())->toBe(UserEntity::class)
        ->and($methodsByName['update']->getParameters()[0]->getType()?->getName())->toBe(UserEntity::class)
        ->and($methodsByName['update']->getReturnType()?->getName())->toBe(UserEntity::class)
        ->and($methodsByName['update']->getReturnType()?->allowsNull())->toBeTrue()
        ->and($methodsByName['delete']->getParameters()[0]->getType()?->getName())->toBe('int')
        ->and($methodsByName['delete']->getReturnType()?->getName())->toBe('bool')
        ->and($methodsByName['all']->getReturnType()?->getName())->toBe('array')
        ->and($methodsByName['findById']->getParameters()[0]->getType()?->getName())->toBe('int')
        ->and($methodsByName['findById']->getReturnType()?->getName())->toBe(UserEntity::class)
        ->and($methodsByName['findById']->getReturnType()?->allowsNull())->toBeTrue()
        ->and($methodsByName['findByEmail']->getParameters()[0]->getType()?->getName())->toBe(EmailValueObject::class)
        ->and($methodsByName['findByEmail']->getReturnType()?->getName())->toBe(UserEntity::class)
        ->and($methodsByName['findByEmail']->getReturnType()?->allowsNull())->toBeTrue();
});
