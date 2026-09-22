<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Identity\Application\Exceptions\EmailAlreadyUsedException;
use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Repositories\IdentityRepository;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;

final readonly class UpdateUserUseCase
{
    public function __construct(private IdentityRepository $repository) {}

    public function execute(int $id, ?string $name, ?string $email): UserEntity
    {
        $current = $this->repository->findById(id: $id)
            ?? throw new UserNotFoundException;
        $updatedEmail = $email === null
            ? $current->email
            : EmailValueObject::fromString(value: $email);

        if (! $updatedEmail->equals(other: $current->email)) {
            $userWithEmail = $this->repository->findByEmail(email: $updatedEmail);

            if ($userWithEmail !== null && $userWithEmail->id !== $id) {
                throw new EmailAlreadyUsedException;
            }
        }

        $updated = new UserEntity(
            id: $id,
            email: $updatedEmail,
            createdAt: $current->createdAt,
            updatedAt: $current->updatedAt,
            name: $name === null ? $current->name : NameValueObject::fromString(value: $name),
        );

        return $this->repository->update(user: $updated)
            ?? throw new UserNotFoundException;
    }
}
