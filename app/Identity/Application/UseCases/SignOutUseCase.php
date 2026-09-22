<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Identity\Application\Ports\SignOutPort;

final readonly class SignOutUseCase
{
    public function __construct(private SignOutPort $port) {}

    public function execute(): void
    {
        $this->port->revokeToken();
    }
}
