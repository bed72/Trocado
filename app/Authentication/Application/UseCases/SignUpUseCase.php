<?php

declare(strict_types=1);

namespace App\Authentication\Application\UseCases;

use App\Authentication\Application\Ports\AuthenticationWritePort;
use App\Authentication\Application\Ports\SignUpPort;
use App\Authentication\Domain\ValueObjects\PasswordValueObject;
use SensitiveParameter;

final readonly class SignUpUseCase
{
    public function __construct(
        private SignUpPort $signUpPort,
        private AuthenticationWritePort $writePort,
    ) {}

    public function execute(string $name, string $email, #[SensitiveParameter] string $password): int
    {
        $validPassword = PasswordValueObject::fromString(value: $password);

        return $this->writePort->execute(
            operation: fn (): int => $this->signUpPort->create(
                name: $name,
                email: $email,
                password: $validPassword->value(),
            ),
        );
    }
}
