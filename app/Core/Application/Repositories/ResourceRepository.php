<?php

declare(strict_types=1);

namespace App\Core\Application\Repositories;

use App\Core\Application\Data\ResourceKeyInput;
use App\Core\Application\Data\ResourceKeyOutput;
use SensitiveParameter;

interface ResourceRepository
{
    /**
     * Resolves a validated, deduplicated batch inside the caller's transaction.
     *
     * @param  list<ResourceKeyInput>  $identities
     * @return list<ResourceKeyOutput>
     */
    public function resolve(string $userId, #[SensitiveParameter] array $identities): array;
}
