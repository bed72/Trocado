<?php

declare(strict_types=1);

namespace App\User\Application\UseCases;

use App\User\Application\Exceptions\EmailAlreadyUsedException;
use App\User\Application\Repositories\UserRepository;
use App\User\Domain\Entities\UserEntity;
use App\User\Domain\ValueObjects\EmailValueObject;

final readonly class CreateUserUseCase
{
    public function __construct(private UserRepository $repository) {}

    public function execute(string $name, string $email): UserEntity
    {
        $user = new UserEntity(
            id: null,
            name: $name,
            email: EmailValueObject::fromString(value: $email),
        );

        if ($this->repository->findByEmail(email: $user->email) !== null) {
            throw new EmailAlreadyUsedException;
        }

        return $this->repository->create(user: $user);
    }
}
