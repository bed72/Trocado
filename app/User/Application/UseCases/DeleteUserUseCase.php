<?php

declare(strict_types=1);

namespace App\User\Application\UseCases;

use App\User\Application\Exceptions\UserNotFoundException;
use App\User\Application\Repositories\UserRepository;

final readonly class DeleteUserUseCase
{
    public function __construct(private UserRepository $repository) {}

    public function execute(int $id): void
    {
        if (! $this->repository->delete(id: $id)) {
            throw new UserNotFoundException(identifier: $id);
        }
    }
}
