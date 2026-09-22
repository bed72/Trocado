<?php

declare(strict_types=1);

use App\Identity\Application\Data\SignInOutput;
use App\Identity\Application\Ports\CreatePort;
use App\Identity\Application\Ports\IdentityWritePort;
use App\Identity\Application\Ports\SignInPort;
use App\Identity\Application\Ports\SignOutPort;
use App\Identity\Domain\Entities\UserEntity;

it('keeps identity capabilities separated behind exact port contracts', function (): void {
    $writeMethods = (new ReflectionClass(IdentityWritePort::class))->getMethods();
    $registrationMethods = (new ReflectionClass(CreatePort::class))->getMethods();
    $signInMethods = (new ReflectionClass(SignInPort::class))->getMethods();
    $signOutMethods = (new ReflectionClass(SignOutPort::class))->getMethods();

    expect(array_column($writeMethods, 'name'))->toBe(['execute'])
        ->and($writeMethods[0]->getParameters())->toHaveCount(1)
        ->and($writeMethods[0]->getParameters()[0]->getType()?->getName())->toBe('callable')
        ->and(array_column($registrationMethods, 'name'))->toBe(['create'])
        ->and($registrationMethods[0]->getParameters())->toHaveCount(2)
        ->and($registrationMethods[0]->getParameters()[0]->getType()?->getName())->toBe(UserEntity::class)
        ->and($registrationMethods[0]->getParameters()[1]->getType()?->getName())->toBe('string')
        ->and($registrationMethods[0]->getParameters()[1]->getAttributes(SensitiveParameter::class))->toHaveCount(1)
        ->and($registrationMethods[0]->getReturnType()?->getName())->toBe(UserEntity::class)
        ->and(array_column($signInMethods, 'name'))->toBe(['issue'])
        ->and($signInMethods[0]->getReturnType()?->getName())->toBe(SignInOutput::class)
        ->and(array_column($signOutMethods, 'name'))->toBe(['revokeToken']);
});
