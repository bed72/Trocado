<?php

declare(strict_types=1);

namespace App\User\Infrastructure\Persistence\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Support\Str;
use Laravel\Sanctum\HasApiTokens;

final class UserModel extends Authenticatable
{
    use HasApiTokens;

    protected $table = 'users';

    protected $fillable = [
        'name',
        'email',
        'password',
    ];

    protected $hidden = [
        'password',
    ];

    protected static function booted(): void
    {
        self::creating(function (self $user): void {
            if ($user->getAttribute('password') === null) {
                $user->setAttribute('password', Str::random(72));
            }
        });
    }

    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'created_at' => 'immutable_datetime',
            'updated_at' => 'immutable_datetime',
        ];
    }
}
