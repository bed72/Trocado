<?php

declare(strict_types=1);

namespace App\Identity\Application\Ports;

interface SignOutPort
{
    public function revokeToken(): void;
}
