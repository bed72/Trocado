<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Repositories\Persistence\Models;

use DateTimeImmutable;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/**
 * @property int $amount
 * @property string $id
 * @property string $user_id
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
    use HasUuids;

    protected function casts(): array
    {
        return [
            'amount' => 'integer',
            'classification_expires_at' => 'immutable_datetime',
            'created_at' => 'immutable_datetime',
            'updated_at' => 'immutable_datetime',
        ];
    }
}
