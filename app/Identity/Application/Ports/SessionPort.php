<?php

declare(strict_types=1);

namespace App\Identity\Application\Ports;

interface SessionPort
{
    public function extendCurrentToken(): void;
}
