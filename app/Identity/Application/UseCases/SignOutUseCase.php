<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\UserPort;
use App\Identity\Application\Ports\SignOutPort;

final readonly class SignOutUseCase
{
    public function __construct(
        private UserPort $userPort,
        private SignOutPort $signOutPort,
        private ObservabilityPort $observabilityPort,
    ) {}

    public function execute(): void
    {
        $userId = $this->userPort->id();
        $this->signOutPort->revokeToken();

        $this->observabilityPort->emit('identity.signed_out', ['user_id' => $userId]);
    }
}
