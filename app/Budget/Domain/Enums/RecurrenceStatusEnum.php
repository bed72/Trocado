<?php

declare(strict_types=1);

namespace App\Budget\Domain\Enums;

enum RecurrenceStatusEnum: string
{
    case Ended = 'ended';
    case Active = 'active';
    case Blocked = 'blocked';
}
