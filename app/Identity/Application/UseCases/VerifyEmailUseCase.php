<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Core\Application\Ports\TransactionPort;
use App\Core\Domain\ValueObjects\UuidValueObject;
use App\Identity\Application\Ports\EmailVerificationPort;
use App\Identity\Application\Repositories\EmailVerificationRepository;

final readonly class VerifyEmailUseCase
{
    public function __construct(
        private TransactionPort $transactionPort,
        private EmailVerificationPort $emailPort,
        private EmailVerificationRepository $repository,
    ) {}

    public function execute(string $userId, string $hash): bool
    {
        $userId = UuidValueObject::fromString($userId)->value();

        return $this->transactionPort->commit(
            function () use ($userId, $hash): bool {
                $verification = $this->repository->verify(userId: $userId, hash: $hash);

                if ($verification->isValid && $verification->wasVerifiedNow) {
                    $this->transactionPort->afterCommit(
                        fn () => $this->emailPort->publishVerified(userId: $userId),
                    );
                }

                return $verification->isValid;
            },
        );
    }
}
