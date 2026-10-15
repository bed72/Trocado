<?php

declare(strict_types=1);

namespace App\Core\Application\Data;

final readonly class ResourceOutput
{
    /** @param list<ResourceKeyOutput> $identities */
    public function __construct(public array $identities) {}
}
