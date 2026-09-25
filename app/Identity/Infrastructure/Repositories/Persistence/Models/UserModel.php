<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Repositories\Persistence\Models;

use App\Identity\Domain\Enums\UserStatusEnum;
use DateTimeImmutable;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

/**
 * @property int $id
 * @property string $name
 * @property string $email
 * @property string $password
 * @property UserStatusEnum $status
 * @property DateTimeImmutable $created_at
 * @property DateTimeImmutable $updated_at
 */
#[Table('users')]
#[Hidden('password')]
#[Fillable('name', 'email', 'password', 'status')]
final class UserModel extends Authenticatable
{
    use HasApiTokens;

    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'status' => UserStatusEnum::class,
            'created_at' => 'immutable_datetime',
            'updated_at' => 'immutable_datetime',
        ];
    }
}
