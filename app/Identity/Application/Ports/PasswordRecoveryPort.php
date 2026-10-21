<?php

declare(strict_types=1);

namespace App\Identity\Application\Ports;

use SensitiveParameter;

interface PasswordRecoveryPort
{
    public function isAvailable(): bool;

    public function requestLink(string $userId, string $email, #[SensitiveParameter] string $token): void;
}
