<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Domain\Entities\UserEntity;

final readonly class GetAllUsersUseCase
{
    public function __construct(private UserRepository $repository) {}

    /** @return list<UserEntity> */
    public function execute(): array
    {
        return $this->repository->all();
    }
}
