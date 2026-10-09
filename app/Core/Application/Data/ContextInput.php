<?php

declare(strict_types=1);

namespace App\Core\Application\Data;

final readonly class ContextInput
{
    public function __construct(
        public ?string $ip,
        public string $path,
        public string $method,
        public string $traceId,
    ) {}
}
