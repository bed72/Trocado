<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Identity\Application\Ports\EmailVerificationPort;
use App\Identity\Domain\ValueObjects\EmailValueObject;

final readonly class ResendEmailVerificationUseCase
{
    public function __construct(private EmailVerificationPort $port) {}

    public function execute(string $email): void
    {
        $this->port->requestForEmail(
            email: EmailValueObject::fromString(value: $email)->value(),
        );
    }
}
