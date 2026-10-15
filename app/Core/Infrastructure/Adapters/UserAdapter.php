<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Adapters;

use App\Core\Application\Ports\UserPort;
use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Core\Domain\ValueObjects\UuidValueObject;
use BackedEnum;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\AuthManager;

use function is_string;

final readonly class UserAdapter implements UserPort
{
    public function __construct(private AuthManager $manager) {}

    public function id(): string
    {
        $id = $this->manager->guard(name: 'sanctum')->id();

        if (! is_string($id)) {
            throw new AuthenticationException;
        }

        try {
            return UuidValueObject::fromString($id)->value();
        } catch (InvalidUuidException) {
            throw new AuthenticationException;
        }
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
