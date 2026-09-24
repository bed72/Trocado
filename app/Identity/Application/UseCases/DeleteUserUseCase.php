<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Ports\UserPort;
use App\Identity\Application\Repositories\UserRepository;

final readonly class DeleteUserUseCase
{
    public function __construct(
        private UserPort $userPort,
        private UserRepository $repository,
        private TransactionPort $transactionPort,
    ) {}

    public function execute(int $id): void
    {
        if ($this->userPort->id() !== $id) {
            throw new UserNotFoundException;
        }

        $this->transactionPort->execute(function () use ($id): void {
            if (! $this->repository->delete(id: $id)) {
                throw new UserNotFoundException;
            }
        });
    }
}
