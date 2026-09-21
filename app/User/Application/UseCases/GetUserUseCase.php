<?php

declare(strict_types=1);

namespace App\User\Application\UseCases;

use App\User\Application\Exceptions\UserNotFoundException;
use App\User\Application\Repositories\UserRepository;
use App\User\Domain\Entities\UserEntity;

final readonly class GetUserUseCase
{
    public function __construct(private UserRepository $repository) {}

    public function execute(int $id): UserEntity
    {
        return $this->repository->findById(id: $id) ?? throw new UserNotFoundException(identifier: $id);
    }
}
