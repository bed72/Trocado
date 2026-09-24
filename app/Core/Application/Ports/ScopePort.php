<?php

declare(strict_types=1);

namespace App\Core\Application\Ports;

interface ScopePort
{
    public function execute(int $userId, callable $operation): mixed;
}
