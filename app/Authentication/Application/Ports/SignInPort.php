<?php

declare(strict_types=1);

namespace App\Authentication\Application\Ports;

use DateTimeImmutable;
use SensitiveParameter;

interface SignInPort
{
    /**
     * @return array{id: int, userId: int, plainTextToken: string, expiresAt: DateTimeImmutable}
     */
    public function issue(string $email, #[SensitiveParameter] string $password): array;
}
