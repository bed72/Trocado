<?php

declare(strict_types=1);

namespace App\Authentication\Application\Ports;

interface AuthenticationWritePort
{
    /**
     * @template TResult
     *
     * @param  callable(): TResult  $operation
     * @return TResult
     */
    public function execute(callable $operation): mixed;
}
