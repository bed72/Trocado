<?php

declare(strict_types=1);

namespace Tests\Support\Expense\Fixtures;

use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;

final class ExpenseSuggestionHistoryFixture
{
    public static function create(int $userId, ?string $description, int $amount, string $occurredOn, string $createdAt): int
    {
        $model = new ExpenseModel;
        $model->forceFill([
            'amount' => $amount,
            'user_id' => $userId,
            'category' => 'other',
            'updated_at' => $createdAt,
            'created_at' => $createdAt,
            'occurred_on' => $occurredOn,
            'description' => $description,
        ])->save();

        return (int) $model->getKey();
    }
}
