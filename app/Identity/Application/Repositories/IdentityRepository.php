<?php

declare(strict_types=1);

namespace App\Identity\Application\Repositories;

use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;

interface IdentityRepository
{
    /** @return list<UserEntity> */
    public function all(): array;

    public function delete(int $id): bool;

    public function findById(int $id): ?UserEntity;

    public function update(UserEntity $user): ?UserEntity;

    public function findByEmail(EmailValueObject $email): ?UserEntity;
}
