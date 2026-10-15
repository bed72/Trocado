<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Core\Application\Ports\UserPort;
use App\Core\Domain\ValueObjects\UuidValueObject;
use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Domain\Entities\UserEntity;

final readonly class GetUserUseCase
{
    public function __construct(private UserPort $port, private UserRepository $repository) {}

    public function execute(string $id): UserEntity
    {
        $id = UuidValueObject::fromString($id)->value();
        if ($this->port->id() !== $id) {
            throw new UserNotFoundException;
        }

        return $this->repository->getById(id: $id) ?? throw new UserNotFoundException;
    }
}
