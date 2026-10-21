<?php

declare(strict_types=1);

namespace App\Identity\Application\Exceptions;

use RuntimeException;

final class CurrentPasswordException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('A nova senha deve ser diferente da atual.');
    }
}
