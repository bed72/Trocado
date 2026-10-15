<?php

declare(strict_types=1);

namespace App\Core\Application\Exceptions;

use RuntimeException;

final class ResourcePersistenceException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('Resource identities could not be resolved.');
    }
}
