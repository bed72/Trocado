<?php

declare(strict_types=1);

namespace App\Core\Application\Exceptions;

use RuntimeException;

final class ResourceRaceException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('Resource identity resolution must be retried.');
    }
}
