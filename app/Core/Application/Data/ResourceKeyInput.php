<?php

declare(strict_types=1);

namespace App\Core\Application\Data;

final readonly class ResourceKeyInput
{
    /** @param array<string, string|int|bool|null> $components */
    public function __construct(
        public string $namespace,
        public array $components,
        public int $identityVersion,
    ) {}
}
