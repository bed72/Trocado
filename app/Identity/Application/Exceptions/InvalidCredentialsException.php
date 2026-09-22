<?php

declare(strict_types=1);

namespace App\Identity\Application\Exceptions;

use RuntimeException;

final class InvalidCredentialsException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct(message: 'As credenciais informadas são inválidas.');
    }
}
