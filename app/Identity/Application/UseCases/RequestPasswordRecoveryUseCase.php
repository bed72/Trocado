<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Ports\PasswordRecoveryPort;
use App\Identity\Application\Repositories\PasswordRecoveryRepository;
use App\Identity\Domain\ValueObjects\EmailValueObject;

final readonly class RequestPasswordRecoveryUseCase
{
    public function __construct(
        private TransactionPort $transactionPort,
        private PasswordRecoveryPort $recoveryPort,
        private PasswordRecoveryRepository $repository,
    ) {}

    public function execute(string $email): void
    {
        $email = EmailValueObject::fromString($email);

        if (! $this->recoveryPort->isAvailable()) {
            return;
        }

        $this->transactionPort->commit(function () use ($email): void {
            $emission = $this->repository->issue($email);

            if ($emission === null || $emission->token === null) {
                return;
            }

            $this->transactionPort->afterCommit(
                fn () => $this->recoveryPort->requestLink($emission->userId, $email->value(), $emission->token),
            );
        });
    }
}
