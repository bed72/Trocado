<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Identity\Application\Ports\SessionPort;

final readonly class ExtendSessionUseCase
{
    public function __construct(private SessionPort $port) {}

    public function execute(): void
    {
        $this->port->extendCurrentToken();
    }
}
