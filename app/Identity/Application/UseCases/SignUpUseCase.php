<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Identity\Application\Ports\CreatePort;
use App\Identity\Application\Ports\IdentityWritePort;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;
use App\Identity\Domain\ValueObjects\PasswordValueObject;
use LogicException;
use SensitiveParameter;

final readonly class SignUpUseCase
{
    public function __construct(
        private CreatePort $createPort,
        private IdentityWritePort $identityPort,
    ) {}

    public function execute(string $name, string $email, #[SensitiveParameter] string $password): int
    {
        $user = new UserEntity(
            id: null,
            name: NameValueObject::fromString(value: $name),
            email: EmailValueObject::fromString(value: $email),
        );
        $validPassword = PasswordValueObject::fromString(value: $password);

        $registeredUser = $this->identityPort->execute(
            operation: fn (): UserEntity => $this->createPort->create(
                user: $user,
                password: $validPassword->value(),
            ),
        );

        return $registeredUser->id
            ?? throw new LogicException(message: 'O registro deve retornar uma identidade persistida.');
    }
}
