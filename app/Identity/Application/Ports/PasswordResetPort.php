<?php

declare(strict_types=1);

namespace App\Identity\Application\Ports;

interface PasswordResetPort
{
    public function requestNotice(string $userId, string $email): void;
}
