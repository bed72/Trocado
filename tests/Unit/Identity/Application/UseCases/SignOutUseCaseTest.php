<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\UserPort;
use App\Identity\Application\Ports\SignOutPort;
use App\Identity\Application\UseCases\SignOutUseCase;

it('delegates current token revocation to the authentication port', function (): void {
    $port = $this->createMock(SignOutPort::class);
    $port->expects($this->once())
        ->method('revokeToken');
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn('017f22e2-79b0-7cc3-98c4-00000000000a');

    (new SignOutUseCase(
        userPort: $userPort,
        signOutPort: $port,
        observabilityPort: $this->createMock(ObservabilityPort::class),
    ))->execute();
});
