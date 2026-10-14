<?php

declare(strict_types=1);

namespace App\Notifications\Application\Exceptions;

use RuntimeException;

final class NotificationRegistrationConflictException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('A instalação ou o destino já possui um vínculo incompatível.');
    }
}
