<?php

declare(strict_types=1);

namespace App\User\Application\UseCases;

use App\User\Application\Exceptions\EmailAlreadyUsedException;
use App\User\Application\Exceptions\UserNotFoundException;
use App\User\Application\Repositories\UserRepository;
use App\User\Domain\Entities\UserEntity;
use App\User\Domain\ValueObjects\EmailValueObject;

final readonly class UpdateUserUseCase
{
    public function __construct(private UserRepository $repository) {}

    public function execute(int $id, ?string $name, ?string $email): UserEntity
    {
        $current = $this->repository->findById(id: $id)
            ?? throw new UserNotFoundException(identifier: $id);
        $updatedEmail = $email === null
            ? $current->email
            : EmailValueObject::fromString(value: $email);

        if (! $updatedEmail->equals(other: $current->email)) {
            $userWithEmail = $this->repository->findByEmail(email: $updatedEmail);

            if ($userWithEmail !== null && $userWithEmail->id !== $id) {
                throw new EmailAlreadyUsedException(email: $updatedEmail);
            }
        }

        $updated = new UserEntity(
            id: $id,
            name: $name ?? $current->name,
            email: $updatedEmail,
            createdAt: $current->createdAt,
            updatedAt: $current->updatedAt,
        );

        return $this->repository->update(user: $updated)
            ?? throw new UserNotFoundException(identifier: $id);
    }
}
