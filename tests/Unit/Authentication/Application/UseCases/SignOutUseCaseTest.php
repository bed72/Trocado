<?php

declare(strict_types=1);

use App\Authentication\Application\Ports\SignOutPort;
use App\Authentication\Application\UseCases\SignOutUseCase;

it('delegates current token revocation to the authentication port', function (): void {
    $port = $this->createMock(SignOutPort::class);
    $port->expects($this->once())
        ->method('revokeCurrentToken');

    (new SignOutUseCase(port: $port))->execute();
});
