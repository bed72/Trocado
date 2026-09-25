<?php

declare(strict_types=1);

namespace App\Identity\Application\Ports;

use App\Identity\Domain\Enums\UserStatusEnum;

interface UserPort
{
    public function id(): int;

    public function status(): UserStatusEnum;
}
