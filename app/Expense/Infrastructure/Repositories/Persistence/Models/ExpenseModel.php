<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Repositories\Persistence\Models;

use DateTimeImmutable;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * @property int $amount
 * @property int $user_id
 * @property string $category
 * @property string $occurred_on
 * @property string|null $description
 * @property string|null $classification_token
 * @property DateTimeImmutable|null $classification_expires_at
 * @property DateTimeImmutable $created_at
 * @property DateTimeImmutable $updated_at
 */
#[Table('expenses')]
#[Fillable('user_id', 'amount', 'occurred_on', 'category', 'description', 'classification_token', 'classification_expires_at')]
final class ExpenseModel extends Model
{
    use SoftDeletes;

    protected function casts(): array
    {
        return [
            'user_id' => 'integer',
            'amount' => 'integer',
            'created_at' => 'immutable_datetime',
            'updated_at' => 'immutable_datetime',
            'deleted_at' => 'immutable_datetime',
            'classification_expires_at' => 'immutable_datetime',
        ];
    }
}
