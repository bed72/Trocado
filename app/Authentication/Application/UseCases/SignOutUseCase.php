<?php

declare(strict_types=1);

namespace App\Authentication\Application\UseCases;

use App\Authentication\Application\Ports\SignOutPort;

final readonly class SignOutUseCase
{
    public function __construct(private SignOutPort $port) {}

    public function execute(): void
    {
        $this->port->revokeCurrentToken();
    }
}
