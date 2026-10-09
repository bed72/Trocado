<?php

declare(strict_types=1);

namespace App\Core\Application\Ports;

interface UserPort
{
    public function id(): int;

    public function status(): string;
}
