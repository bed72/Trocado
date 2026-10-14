<?php

declare(strict_types=1);

namespace App\Notifications\Application\Exceptions;

use RuntimeException;

final class NotificationRegistrationNotFoundException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('O registro push não foi encontrado.');
    }
}
