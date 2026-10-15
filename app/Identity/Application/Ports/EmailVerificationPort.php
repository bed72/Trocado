<?php

declare(strict_types=1);

namespace App\Identity\Application\Ports;

interface EmailVerificationPort
{
    public function requestForEmail(string $email): void;

    public function publishVerified(string $userId): void;

    public function requestForRegistration(string $id): void;
}
