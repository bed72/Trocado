<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Data\Input\SignUpInput;
use App\Identity\Application\Ports\EmailVerificationPort;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;
use App\Identity\Domain\ValueObjects\PasswordValueObject;
use LogicException;
use SensitiveParameter;

final readonly class SignUpUseCase
{
    public function __construct(
        private TransactionPort $transactionPort,
        private EmailVerificationPort $emailPort,
        private ObservabilityPort $observabilityPort,
        private UserRepository $repository,
    ) {}

    public function execute(#[SensitiveParameter] SignUpInput $input): int
    {
        $user = new UserEntity(
            id: null,
            avatar: $input->avatar,
            name: NameValueObject::fromString(value: $input->name),
            email: EmailValueObject::fromString(value: $input->email),
        );
        $validPassword = PasswordValueObject::fromString(value: $input->password);

        $registered = $this->transactionPort->commit(function () use ($user, $validPassword): UserEntity {
            $registered = $this->repository->create(user: $user, password: $validPassword->value());
            $registeredId = $registered->id
                ?? throw new LogicException(message: 'O registro deve retornar uma identidade persistida.');

            $this->transactionPort->afterCommit(fn () => $this->observabilityPort->emit('user.registered', [
                'user_id' => $registeredId,
            ]));

            $this->transactionPort->afterCommit(
                fn () => $this->emailPort->requestForRegistration(userId: $registeredId),
            );

            return $registered;
        });

        return $registered->id
            ?? throw new LogicException(message: 'O registro deve retornar uma identidade persistida.');
    }
}
