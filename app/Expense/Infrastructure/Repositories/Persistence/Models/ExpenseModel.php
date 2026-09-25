<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Repositories\Persistence\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

final class ExpenseModel extends Model
{
    use SoftDeletes;

    public const UPDATED_AT = null;

    protected $table = 'expenses';

    protected $fillable = ['user_id', 'amount', 'occurred_on', 'category', 'description'];

    protected function casts(): array
    {
        return [
            'user_id' => 'integer',
            'amount' => 'integer',
            'created_at' => 'immutable_datetime',
            'deleted_at' => 'immutable_datetime',
        ];
    }
}
