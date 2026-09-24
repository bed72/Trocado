<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Ports\UserPort;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Domain\Entities\UserEntity;

final readonly class GetUserUseCase
{
    public function __construct(private UserPort $port, private UserRepository $repository) {}

    public function execute(int $id): UserEntity
    {
        if ($this->port->id() !== $id) {
            throw new UserNotFoundException;
        }

        return $this->repository->findById(id: $id) ?? throw new UserNotFoundException;
    }
}
