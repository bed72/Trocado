<?php

declare(strict_types=1);

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Data\SignInOutput;
use App\Identity\Application\Ports\SignInPort;
use App\Identity\Application\Ports\SignOutPort;

it('keeps identity capabilities separated behind exact port contracts', function (): void {
    $writeMethods = (new ReflectionClass(TransactionPort::class))->getMethods();
    $signInMethods = (new ReflectionClass(SignInPort::class))->getMethods();
    $signOutMethods = (new ReflectionClass(SignOutPort::class))->getMethods();

    expect(array_column($writeMethods, 'name'))->toBe(['execute', 'afterCommit'])
        ->and($writeMethods[0]->getParameters())->toHaveCount(1)
        ->and($writeMethods[0]->getParameters()[0]->getType()?->getName())->toBe('callable')
        ->and($writeMethods[1]->getParameters()[0]->getType()?->getName())->toBe('callable')
        ->and(array_column($signInMethods, 'name'))->toBe(['issue'])
        ->and($signInMethods[0]->getReturnType()?->getName())->toBe(SignInOutput::class)
        ->and(array_column($signOutMethods, 'name'))->toBe(['revokeToken']);
});
