<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;

final readonly class GetUserByEmailUseCase
{
    public function __construct(private UserRepository $repository) {}

    public function execute(string $email): UserEntity
    {
        $canonicalEmail = EmailValueObject::fromString(value: $email);

        return $this->repository->findByEmail(email: $canonicalEmail)
            ?? throw new UserNotFoundException;
    }
}
