<?php

declare(strict_types=1);

namespace App\Notifications\Application\Exceptions;

use RuntimeException;

final class NotificationRegistrationPersistenceException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('Não foi possível persistir o registro push.');
    }
}
