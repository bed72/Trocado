<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Adapters;

use App\Core\Application\Ports\UserPort;
use BackedEnum;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\AuthManager;

use function is_int;
use function is_string;

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

    public function status(): string
    {
        $status = $this->manager->guard(name: 'sanctum')->user()?->status;

        if ($status instanceof BackedEnum) {
            $status = $status->value;
        }

        if (! is_string($status)) {
            throw new AuthenticationException;
        }

        return $status;
    }
}
