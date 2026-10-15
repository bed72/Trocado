<?php

declare(strict_types=1);

namespace App\Core\Application\Data;

final readonly class ResourceKeyOutput
{
    public function __construct(public ResourceKeyInput $identity, public string $id) {}
}
