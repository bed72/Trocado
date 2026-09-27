<?php

declare(strict_types=1);

namespace App\Identity\Application\Ports;

interface EmailVerificationPort
{
    public function requestForEmail(string $email): void;

    public function verify(int $userId, string $hash): bool;

    public function requestForRegistration(int $userId): void;
}
