<?php

declare(strict_types=1);

use App\Identity\Application\Ports\CreatePort;
use App\Identity\Application\Ports\IdentityWritePort;
use App\Identity\Application\UseCases\SignUpUseCase;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\Exceptions\InvalidPasswordException;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;

it('registers the canonical identity inside the transaction and returns its identifier', function (): void {
    $persisted = new UserEntity(
        id: 10,
        name: NameValueObject::fromString(value: 'Maria'),
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    );
    $writePort = $this->createMock(IdentityWritePort::class);
    $registrationPort = $this->createMock(CreatePort::class);
    $writePort->expects($this->once())
        ->method('execute')
        ->willReturnCallback(static fn (callable $operation): mixed => $operation());
    $registrationPort->expects($this->once())
        ->method('create')
        ->with(
            $this->callback(fn (UserEntity $user): bool => $user->id === null
                && $user->name->value() === 'Maria'
                && $user->email->value() === 'maria@example.com'),
            ' Abc123 ',
        )
        ->willReturn($persisted);

    $result = (new SignUpUseCase(
        createPort: $registrationPort,
        identityPort: $writePort,
    ))->execute(
        name: ' Maria ',
        email: ' MARIA@EXAMPLE.COM ',
        password: ' Abc123 ',
    );

    expect($result)->toBe(10);
});

it('rejects an invalid password before opening a transaction', function (): void {
    $writePort = $this->createMock(IdentityWritePort::class);
    $registrationPort = $this->createMock(CreatePort::class);
    $writePort->expects($this->never())->method('execute');
    $registrationPort->expects($this->never())->method('create');

    (new SignUpUseCase(
        createPort: $registrationPort,
        identityPort: $writePort,
    ))->execute(
        name: 'Maria',
        email: 'maria@example.com',
        password: 'abc12',
    );
})->throws(InvalidPasswordException::class);
