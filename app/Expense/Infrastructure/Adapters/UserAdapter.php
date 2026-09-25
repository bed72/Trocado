<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Adapters;

use App\Expense\Application\Ports\UserPort;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\AuthManager;

final readonly class UserAdapter implements UserPort
{
    public function __construct(private AuthManager $manager) {}

    public function id(): int
    {
        $id = $this->manager->guard(name: 'sanctum')->id();

        if (! is_int($id)) {
            throw new AuthenticationException;
        }

        return $id;
    }
}
