<?php

declare(strict_types=1);

namespace App\Identity\Application\Exceptions;

use RuntimeException;

final class UserNotFoundException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct(message: 'User não encontrado.');
    }
}
