<?php

declare(strict_types=1);

namespace App\Authentication\Application\Ports;

interface SignOutPort
{
    public function revokeCurrentToken(): void;
}
