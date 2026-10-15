<?php

declare(strict_types=1);

namespace App\Core\Application\Ports;

interface UserPort
{
    public function id(): string;

    public function status(): string;
}
