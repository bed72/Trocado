<?php

declare(strict_types=1);

namespace Tests\Support\Identity\Fixtures;

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use DateTimeInterface;

final class IdentityFixture
{
    public static function create(
        UserStatusEnum $status,
        ?DateTimeInterface $verifiedAt,
        string $name = 'Maria',
        string $email = 'maria@example.com',
        string $password = 'Correct1',
    ): UserModel {
        $user = new UserModel;
        $user->forceFill([
            'name' => $name,
            'email' => $email,
            'password' => $password,
            'status' => $status,
            'email_verified_at' => $verifiedAt,
        ])->save();

        return $user;
    }

    public static function token(UserModel $user, ?DateTimeInterface $expiresAt, string $name = 'test'): string
    {
        return $user->createToken(name: $name, abilities: ['*'], expiresAt: $expiresAt)->plainTextToken;
    }
}
