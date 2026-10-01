<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Identity\Application\Ports\SessionExtensionPort;

final readonly class ExtendSessionUseCase
{
    public function __construct(private SessionExtensionPort $port) {}

    public function execute(): void
    {
        $this->port->extendCurrentToken(windowDays: 15, validityDays: 30, maximumAgeDays: 90);
    }
}
