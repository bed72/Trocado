<?php

declare(strict_types=1);

namespace Tests\Support\Expense\Fixtures;

use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;

final class ExpenseSuggestionHistoryFixture
{
    public static function create(string $userId, ?string $description, int $amount, string $occurredOn, string $createdAt, ?string $id = null): string
    {
        $model = new ExpenseModel;
        if ($id !== null) {
            $model->id = $id;
        }
        $model->forceFill([
            'amount' => $amount,
            'user_id' => $userId,
            'category' => 'other',
            'updated_at' => $createdAt,
            'created_at' => $createdAt,
            'occurred_on' => $occurredOn,
            'description' => $description,
        ])->save();

        return $model->getKey();
    }
}
