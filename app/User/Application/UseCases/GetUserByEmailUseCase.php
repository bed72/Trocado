<?php

declare(strict_types=1);

namespace App\User\Application\UseCases;

use App\User\Application\Exceptions\UserNotFoundException;
use App\User\Application\Repositories\UserRepository;
use App\User\Domain\Entities\UserEntity;
use App\User\Domain\ValueObjects\EmailValueObject;

final readonly class GetUserByEmailUseCase
{
    public function __construct(private UserRepository $repository) {}

    public function execute(string $email): UserEntity
    {
        $canonicalEmail = EmailValueObject::fromString(value: $email);

        return $this->repository->findByEmail(email: $canonicalEmail)
            ?? throw new UserNotFoundException(identifier: $canonicalEmail->value());
    }
}
