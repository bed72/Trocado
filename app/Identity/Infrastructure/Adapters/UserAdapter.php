<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Adapters;

use App\Identity\Application\Ports\UserPort;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\AuthManager;

final readonly class UserAdapter implements UserPort
{
    public function __construct(private AuthManager $manager) {}

    public function status(): UserStatusEnum
    {
        return $this->authenticated()->status;
    }

    public function id(): int
    {
        return (int) $this->authenticated()->getKey();
    }

    private function authenticated(): UserModel
    {
        $user = $this->manager->guard(name: 'sanctum')->user();

        if (! $user instanceof UserModel) {
            throw new AuthenticationException;
        }

        return $user;
    }
}
