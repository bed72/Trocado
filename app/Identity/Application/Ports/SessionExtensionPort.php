<?php

declare(strict_types=1);

namespace App\Identity\Application\Ports;

interface SessionExtensionPort
{
    public function extendCurrentToken(int $windowDays, int $validityDays, int $maximumAgeDays): void;
}
