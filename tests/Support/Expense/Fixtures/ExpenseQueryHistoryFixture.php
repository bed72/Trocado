<?php

declare(strict_types=1);

namespace Tests\Support\Expense\Fixtures;

use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;

final class ExpenseQueryHistoryFixture
{
    public static function create(int $userId, string $date, int $amount, string $category, ?string $description = null): int
    {
        return (int) ExpenseModel::query()->create([
            'user_id' => $userId, 'occurred_on' => $date, 'amount' => $amount, 'category' => $category, 'description' => $description,
            'created_at' => '2026-10-11 12:00:00', 'updated_at' => '2026-10-11 12:00:00',
        ])->getKey();
    }
}
