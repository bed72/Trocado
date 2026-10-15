<?php

declare(strict_types=1);

namespace App\Identity\Application\Repositories;

use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use SensitiveParameter;

interface UserRepository
{
    public function delete(string $id): bool;

    public function getById(string $id): ?UserEntity;

    public function update(UserEntity $user): ?UserEntity;

    public function getByEmail(EmailValueObject $email): ?UserEntity;

    public function create(UserEntity $user, #[SensitiveParameter] string $password): UserEntity;
}
