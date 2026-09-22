<?php

declare(strict_types=1);

namespace App\Identity\Application\Ports;

use App\Identity\Domain\Entities\UserEntity;
use SensitiveParameter;

interface CreatePort
{
    public function create(UserEntity $user, #[SensitiveParameter] string $password): UserEntity;
}
