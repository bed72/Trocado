<?php

declare(strict_types=1);

use App\Authentication\Application\Ports\AuthenticationWritePort;
use App\Authentication\Application\Ports\SignUpPort;
use App\Authentication\Application\UseCases\SignUpUseCase;
use App\Authentication\Domain\Exceptions\InvalidPasswordException;

it('defines the atomic sign up operation and preserves the password', function (): void {
    $writePort = $this->createMock(AuthenticationWritePort::class);
    $signUpPort = $this->createMock(SignUpPort::class);
    $writePort->expects($this->once())
        ->method('execute')
        ->willReturnCallback(static fn (callable $operation): mixed => $operation());
    $signUpPort->expects($this->once())
        ->method('create')
        ->with(' Maria ', ' MARIA@EXAMPLE.COM ', ' Abc123 ')
        ->willReturn(10);

    $result = (new SignUpUseCase(writePort: $writePort, signUpPort: $signUpPort))->execute(
        name: ' Maria ',
        email: ' MARIA@EXAMPLE.COM ',
        password: ' Abc123 ',
    );

    expect($result)->toBe(10);
});

it('rejects an invalid password before opening a transaction', function (): void {
    $writePort = $this->createMock(AuthenticationWritePort::class);
    $signUpPort = $this->createMock(SignUpPort::class);
    $writePort->expects($this->never())->method('execute');
    $signUpPort->expects($this->never())->method('create');

    (new SignUpUseCase(writePort: $writePort, signUpPort: $signUpPort))->execute(
        name: 'Maria',
        email: 'maria@example.com',
        password: 'abc12',
    );
})->throws(InvalidPasswordException::class);
