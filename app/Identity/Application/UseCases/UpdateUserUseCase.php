<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Exceptions\EmailAlreadyUsedException;
use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Ports\UserPort;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;

final readonly class UpdateUserUseCase
{
    public function __construct(
        private UserPort $userPort,
        private UserRepository $repository,
        private TransactionPort $transactionPort,
        private ObservabilityPort $observabilityPort,
    ) {}

    public function execute(int $id, ?string $name, ?string $email): UserEntity
    {
        if ($this->userPort->id() !== $id) {
            throw new UserNotFoundException;
        }

        $current = $this->repository->findById(id: $id)
            ?? throw new UserNotFoundException;
        $updatedEmail = $email === null
            ? $current->email
            : EmailValueObject::fromString(value: $email);

        if (! $updatedEmail->equals(other: $current->email)) {
            $userWithEmail = $this->repository->findByEmail(email: $updatedEmail);

            if ($userWithEmail !== null && $userWithEmail->id !== $id) {
                throw new EmailAlreadyUsedException;
            }
        }

        $updated = new UserEntity(
            id: $id,
            email: $updatedEmail,
            status: $current->status,
            createdAt: $current->createdAt,
            updatedAt: $current->updatedAt,
            name: $name === null ? $current->name : NameValueObject::fromString(value: $name),
        );

        $saved = $this->repository->update(user: $updated)
            ?? throw new UserNotFoundException;

        $this->transactionPort->afterCommit(fn () => $this->observabilityPort->emit('user.updated', [
            'user_id' => $id,
        ]));

        return $saved;
    }
}
