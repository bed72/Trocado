<?php

declare(strict_types=1);

namespace App\Identity\Application\Ports;

interface IdentityWritePort
{
    /**
     * @template TResult
     *
     * @param  callable(): TResult  $operation
     * @return TResult
     */
    public function execute(callable $operation): mixed;
}
