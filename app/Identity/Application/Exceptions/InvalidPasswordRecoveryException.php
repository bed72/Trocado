<?php

declare(strict_types=1);

namespace App\Identity\Application\Exceptions;

use RuntimeException;

final class InvalidPasswordRecoveryException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('Este link é inválido ou expirou. Solicite uma nova recuperação de senha.');
    }
}
