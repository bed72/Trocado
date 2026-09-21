<?php

declare(strict_types=1);

namespace App\User\Application\UseCases;

use App\User\Application\Repositories\UserRepository;
use App\User\Domain\Entities\UserEntity;

final readonly class GetAllUsersUseCase
{
    public function __construct(private UserRepository $repository) {}

    /** @return list<UserEntity> */
    public function execute(): array
    {
        return $this->repository->all();
    }
}
