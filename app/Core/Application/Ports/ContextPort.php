<?php

declare(strict_types=1);

namespace App\Core\Application\Ports;

use App\Core\Application\Data\ContextInput;

interface ContextPort
{
    public function traceId(): ?string;

    public function identifyUser(int $userId): void;

    public function capture(ContextInput $input): void;

    public function identifyRoute(string $route): void;

    /**
     * @template TReturn
     *
     * @param  callable(): TReturn  $operation
     * @return TReturn
     */
    public function scope(callable $operation): mixed;
}
