<?php

declare(strict_types=1);

namespace App\Notifications\Domain\Enums;

enum NotificationPlatformEnum: string
{
    case Ios = 'ios';
    case Android = 'android';
}
