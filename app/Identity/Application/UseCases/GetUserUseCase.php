<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Repositories\IdentityRepository;
use App\Identity\Domain\Entities\UserEntity;

final readonly class GetUserUseCase
{
    public function __construct(private IdentityRepository $repository) {}

    public function execute(int $id): UserEntity
    {
        return $this->repository->findById(id: $id) ?? throw new UserNotFoundException;
    }
}
