<?php

declare(strict_types=1);

namespace App\Identity\Application\Ports;

interface EmailVerificationPort
{
    public function requestForEmail(string $email): void;

    public function requestForRegistration(int $userId): void;

    public function publishVerified(int $userId): void;
}
