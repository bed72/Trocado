<?php

declare(strict_types=1);

namespace App\User\Application\Exceptions;

use RuntimeException;

final class UserNotFoundException extends RuntimeException
{
    public function __construct(int|string $identifier)
    {
        parent::__construct(message: "User {$identifier} não encontrado.");
    }
}
