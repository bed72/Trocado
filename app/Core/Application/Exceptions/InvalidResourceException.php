<?php

declare(strict_types=1);

namespace App\Core\Application\Exceptions;

use InvalidArgumentException;

final class InvalidResourceException extends InvalidArgumentException
{
    public function __construct()
    {
        parent::__construct('Invalid resource identity batch.');
    }
}
