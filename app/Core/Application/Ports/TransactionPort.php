<?php

declare(strict_types=1);

namespace App\Core\Application\Ports;

interface TransactionPort
{
    /**
     * @template TResult
     *
     * @param  callable(): TResult  $operation
     * @return TResult
     */
    public function execute(callable $operation): mixed;

    /** @param callable(): void $callback */
    public function afterCommit(callable $callback): void;
}
