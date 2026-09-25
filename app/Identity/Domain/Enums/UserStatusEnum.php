<?php

declare(strict_types=1);

namespace App\Identity\Domain\Enums;

enum UserStatusEnum: string
{
    case Active = 'active';
    case Blocked = 'blocked';
    case Pending = 'pending';
}
