<?php

declare(strict_types=1);

use App\Identity\Application\Ports\SignOutPort;
use App\Identity\Application\UseCases\SignOutUseCase;

it('delegates current token revocation to the authentication port', function (): void {
    $port = $this->createMock(SignOutPort::class);
    $port->expects($this->once())
        ->method('revokeToken');

    (new SignOutUseCase(port: $port))->execute();
});
