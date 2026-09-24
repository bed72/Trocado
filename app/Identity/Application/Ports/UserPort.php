<?php

declare(strict_types=1);

namespace App\Identity\Application\Ports;

interface UserPort
{
    public function id(): int;
}
