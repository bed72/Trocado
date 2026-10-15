<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Repositories\Persistence\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

final class ResourceModel extends Model
{
    use HasUuids;

    protected $table = 'resource_identities';

    public const UPDATED_AT = null;

    protected function casts(): array
    {
        return ['identity_version' => 'integer', 'created_at' => 'immutable_datetime'];
    }
}
