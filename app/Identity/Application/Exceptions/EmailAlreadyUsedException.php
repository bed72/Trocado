<?php

declare(strict_types=1);

namespace App\Identity\Application\Exceptions;

use RuntimeException;

final class EmailAlreadyUsedException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct(message: 'Não foi possível utilizar o e-mail informado.');
    }
}
