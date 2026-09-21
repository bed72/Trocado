<?php

declare(strict_types=1);

namespace App\Authentication\Application\UseCases;

use App\Authentication\Application\Ports\SignInPort;
use DateTimeImmutable;
use SensitiveParameter;

final readonly class SignInUseCase
{
    public function __construct(private SignInPort $port) {}

    /**
     * @return array{id: int, userId: int, plainTextToken: string, expiresAt: DateTimeImmutable}
     */
    public function execute(string $email, #[SensitiveParameter] string $password): array
    {
        return $this->port->issue(email: $email, password: $password);
    }
}
