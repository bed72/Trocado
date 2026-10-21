<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Data\Input\ResetPasswordInput;
use App\Identity\Application\Ports\PasswordResetPort;
use App\Identity\Application\Repositories\PasswordRecoveryRepository;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\PasswordValueObject;
use SensitiveParameter;

final readonly class ResetPasswordUseCase
{
    public function __construct(
        private PasswordResetPort $resetPort,
        private TransactionPort $transactionPort,
        private PasswordRecoveryRepository $repository,
    ) {}

    public function execute(#[SensitiveParameter] ResetPasswordInput $input): void
    {
        $email = EmailValueObject::fromString($input->email);
        $password = PasswordValueObject::fromString($input->password);

        $this->transactionPort->commit(function () use ($input, $email, $password): void {
            $userId = $this->repository->reset($email, $input->token, $password);
            $this->transactionPort->afterCommit(
                fn () => $this->resetPort->requestNotice($userId, $email->value()),
            );
        });
    }
}
