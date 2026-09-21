<?php

declare(strict_types=1);

namespace App\Budget\Application\Ports;

interface BudgetWritePort
{
    /**
     * @template TResult
     *
     * @param  callable(): TResult  $operation
     * @return TResult
     */
    public function execute(callable $operation): mixed;
}
