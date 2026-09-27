<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Ports\EmailVerificationPort;

final readonly class VerifyEmailUseCase
{
    public function __construct(private TransactionPort $transactionPort, private EmailVerificationPort $port) {}

    public function execute(int $userId, string $hash): bool
    {
        return $this->transactionPort->execute(
            fn (): bool => $this->port->verify(userId: $userId, hash: $hash),
        );
    }
}
