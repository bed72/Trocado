<?php

declare(strict_types=1);

namespace App\Core\Application\Data;

final readonly class ResourceInput
{
    /** @param list<ResourceKeyInput> $identities */
    public function __construct(public string $userId, public array $identities) {}
}
