<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Ports\IdentityWritePort;
use App\Identity\Application\Repositories\IdentityRepository;

final readonly class DeleteUserUseCase
{
    public function __construct(
        private IdentityWritePort $port,
        private IdentityRepository $repository,
    ) {}

    public function execute(int $id): void
    {
        $this->port->execute(function () use ($id): void {
            if (! $this->repository->delete(id: $id)) {
                throw new UserNotFoundException;
            }
        });
    }
}
