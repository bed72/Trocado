<?php

declare(strict_types=1);

namespace App\Budget\Infrastructure\Persistence\Models;

use Illuminate\Database\Eloquent\Model;

final class BudgetModel extends Model
{
    protected $table = 'budgets';

    protected $fillable = [
        'amount',
        'end_date',
        'start_date',
        'recurrence_id',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'integer',
            'end_date' => 'immutable_date',
            'start_date' => 'immutable_date',
            'recurrence_id' => 'integer',
            'created_at' => 'immutable_datetime',
            'updated_at' => 'immutable_datetime',
        ];
    }
}
