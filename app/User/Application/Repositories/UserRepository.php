<?php

declare(strict_types=1);

namespace App\User\Application\Repositories;

use App\User\Domain\Entities\UserEntity;
use App\User\Domain\ValueObjects\EmailValueObject;

interface UserRepository
{
    public function create(UserEntity $user): UserEntity;

    public function update(UserEntity $user): ?UserEntity;

    public function delete(int $id): bool;

    /** @return list<UserEntity> */
    public function all(): array;

    public function findById(int $id): ?UserEntity;

    public function findByEmail(EmailValueObject $email): ?UserEntity;
}
