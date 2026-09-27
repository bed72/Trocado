<?php

declare(strict_types=1);

namespace App\Identity\Application\Exceptions;

use RuntimeException;

final class UnverifiedEmailException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct(message: 'O endereço de e-mail ainda não foi confirmado.');
    }
}
