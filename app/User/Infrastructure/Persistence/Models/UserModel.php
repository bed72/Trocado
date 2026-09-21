<?php

declare(strict_types=1);

namespace App\User\Infrastructure\Persistence\Models;

use Illuminate\Database\Eloquent\Model;

final class UserModel extends Model
{
    protected $table = 'users';

    protected $fillable = [
        'name',
        'email',
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'immutable_datetime',
            'updated_at' => 'immutable_datetime',
        ];
    }
}
