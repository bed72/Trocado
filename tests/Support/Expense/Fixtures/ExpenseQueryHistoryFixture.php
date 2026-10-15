<?php

declare(strict_types=1);

namespace Tests\Support\Expense\Fixtures;

use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;

final class ExpenseQueryHistoryFixture
{
    public static function create(string $userId, string $date, int $amount, string $category, ?string $description = null, ?string $id = null): string
    {
        $model = new ExpenseModel;
        if ($id !== null) {
            $model->id = $id;
        }

        $model->fill([
            'user_id' => $userId, 'occurred_on' => $date, 'amount' => $amount, 'category' => $category, 'description' => $description,
            'created_at' => '2026-10-11 12:00:00', 'updated_at' => '2026-10-11 12:00:00',
        ])->save();

        return $model->getKey();
    }
}
