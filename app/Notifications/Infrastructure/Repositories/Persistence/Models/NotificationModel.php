<?php

declare(strict_types=1);

namespace App\Notifications\Infrastructure\Repositories\Persistence\Models;

use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Model;

#[Table('notifications')]
#[Hidden('registration_identifier', 'identifier_fingerprint', 'session_id', 'user_id', 'generation')]
final class NotificationModel extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $dateFormat = 'Y-m-d H:i:s.uP';

    protected function casts(): array
    {
        return [
            'generation' => 'integer',
            'registration_identifier' => 'encrypted',
            'last_registered_at' => 'immutable_datetime',
            'created_at' => 'immutable_datetime',
            'updated_at' => 'immutable_datetime',
        ];
    }
}
