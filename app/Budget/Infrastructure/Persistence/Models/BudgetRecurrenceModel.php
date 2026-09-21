<?php

declare(strict_types=1);

namespace App\Budget\Infrastructure\Persistence\Models;

use Illuminate\Database\Eloquent\Model;

final class BudgetRecurrenceModel extends Model
{
    protected $table = 'budget_recurrences';

    protected $fillable = [
        'status',
        'amount',
        'ended_at',
        'blocked_at',
        'next_start_date',
        'duration_in_days',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'integer',
            'duration_in_days' => 'integer',
            'ended_at' => 'immutable_datetime',
            'blocked_at' => 'immutable_datetime',
            'created_at' => 'immutable_datetime',
            'updated_at' => 'immutable_datetime',
            'next_start_date' => 'immutable_date',
        ];
    }
}
