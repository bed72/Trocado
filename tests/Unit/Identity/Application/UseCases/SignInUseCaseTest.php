<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Identity\Application\Data\SignInOutput;
use App\Identity\Application\Ports\SignInPort;
use App\Identity\Application\UseCases\SignInUseCase;

it('delegates credential verification and token issuance to the authentication port', function (): void {
    $expiresAt = new DateTimeImmutable('2026-09-21T12:00:00+00:00');
    $issuedToken = new SignInOutput(
        id: 5,
        userId: 10,
        token: 'plain-token',
        expiresAt: $expiresAt,
    );
    $port = $this->createMock(SignInPort::class);
    $port->expects($this->once())
        ->method('issue')
        ->with(' Maria@Example.COM ', 'Abc123')
        ->willReturn($issuedToken);

    expect((new SignInUseCase(signInPort: $port, observabilityPort: $this->createMock(ObservabilityPort::class)))->execute(
        email: ' Maria@Example.COM ',
        password: 'Abc123',
    ))->toBe($issuedToken);
});
