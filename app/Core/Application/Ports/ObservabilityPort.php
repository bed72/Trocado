<?php

declare(strict_types=1);

namespace App\Core\Application\Ports;

interface ObservabilityPort
{
    /**
     * @param  array<string, bool|float|int|string|null>  $attributes
     */
    public function emit(string $event, array $attributes): void;
}
