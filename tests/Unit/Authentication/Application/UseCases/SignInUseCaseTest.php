<?php

declare(strict_types=1);

use App\Authentication\Application\Data\SignInOutput;
use App\Authentication\Application\Ports\SignInPort;
use App\Authentication\Application\UseCases\SignInUseCase;

it('delegates credential verification and token issuance to the authentication port', function (): void {
    $expiresAt = new DateTimeImmutable('2026-09-21T12:00:00+00:00');
    $issuedToken = new SignInOutput(
        id: 5,
        userId: 10,
        plainTextToken: 'plain-token',
        expiresAt: $expiresAt,
    );
    $port = $this->createMock(SignInPort::class);
    $port->expects($this->once())
        ->method('issue')
        ->with(' Maria@Example.COM ', 'Abc123')
        ->willReturn($issuedToken);

    expect((new SignInUseCase(port: $port))->execute(
        email: ' Maria@Example.COM ',
        password: 'Abc123',
    ))->toBe($issuedToken);
});
