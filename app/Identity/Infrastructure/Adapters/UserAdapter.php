<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Adapters;

use App\Identity\Application\Ports\UserPort;
use App\Identity\Infrastructure\Persistence\Models\UserModel;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\AuthManager;

final readonly class UserAdapter implements UserPort
{
    public function __construct(private AuthManager $manager) {}

    public function id(): int
    {
        $user = $this->manager->guard(name: 'sanctum')->user();

        if (! $user instanceof UserModel) {
            throw new AuthenticationException;
        }

        return (int) $user->getKey();
    }
}
