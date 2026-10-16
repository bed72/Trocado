<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Repositories\Persistence\Models;

use App\Identity\Domain\Enums\UserStatusEnum;
use DateTimeImmutable;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

/**
 * @property string $id
 * @property string $name
 * @property string $email
 * @property string $password
 * @property string|null $avatar
 * @property UserStatusEnum $status
 * @property DateTimeImmutable $created_at
 * @property DateTimeImmutable $updated_at
 * @property DateTimeImmutable|null $email_verified_at
 */
#[Table('users')]
#[Hidden('password')]
#[Fillable('name', 'email', 'password', 'status', 'avatar')]
final class UserModel extends Authenticatable implements MustVerifyEmail
{
    use HasApiTokens, HasUuids, Notifiable;

    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'status' => UserStatusEnum::class,
            'email_verified_at' => 'immutable_datetime',
            'created_at' => 'immutable_datetime',
            'updated_at' => 'immutable_datetime',
        ];
    }
}
