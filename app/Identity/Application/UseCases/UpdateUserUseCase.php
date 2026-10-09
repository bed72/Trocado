<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\UserPort;
use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\NameValueObject;

final readonly class UpdateUserUseCase
{
    public function __construct(
        private UserPort $userPort,
        private ObservabilityPort $observabilityPort,
        private UserRepository $repository,
    ) {}

    public function execute(int $id, string $name): UserEntity
    {
        if ($this->userPort->id() !== $id) {
            throw new UserNotFoundException;
        }

        $current = $this->repository->getById(id: $id)
            ?? throw new UserNotFoundException;

        $updated = new UserEntity(
            id: $id,
            email: $current->email,
            status: $current->status,
            createdAt: $current->createdAt,
            updatedAt: $current->updatedAt,
            name: NameValueObject::fromString(value: $name),
        );

        $saved = $this->repository->update(user: $updated)
            ?? throw new UserNotFoundException;

        $this->observabilityPort->emit('user.updated', ['user_id' => $id]);

        return $saved;
    }
}
