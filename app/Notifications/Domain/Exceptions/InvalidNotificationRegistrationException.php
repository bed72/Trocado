<?php

declare(strict_types=1);

namespace App\Notifications\Domain\Exceptions;

use InvalidArgumentException;

final class InvalidNotificationRegistrationException extends InvalidArgumentException
{
    public function __construct(public readonly string $field)
    {
        parent::__construct('O campo do registro push é inválido.');
    }
}
