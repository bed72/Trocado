<?php

declare(strict_types=1);

namespace App\Expense\Application\Ports;

interface UserPort
{
    public function id(): int;
}
