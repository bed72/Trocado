<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Core\Domain\Enums\ExpenseCategoryEnum;
use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Carbon\CarbonImmutable;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

use function count;

final class ExpenseSeeder extends Seeder
{
    private const int BATCH_SIZE = 500;

    private const int EXPENSES_PER_USER = 10_000;

    public function run(): void
    {
        $today = CarbonImmutable::today(config('app.timezone'));
        $expenses = $this->expenseTemplates();
        $currentMonth = $today->startOfMonth();
        $firstDate = $currentMonth->subMonths(5);
        $days = (int) $firstDate->diffInDays($today) + 1;
        $timestamp = CarbonImmutable::now(config('app.timezone'));

        foreach (UserModel::query()->select('id')->lazyById() as $user) {
            $existing = ExpenseModel::query()->where('user_id', $user->id)->count();
            $batch = [];

            for ($index = $existing; $index < self::EXPENSES_PER_USER; $index++) {
                $expense = $expenses[$index % count($expenses)];
                $date = $firstDate->addDays($index % $days);
                $percentage = $date->greaterThanOrEqualTo($currentMonth) ? 135 : 100;

                $batch[] = [
                    'id' => (string) Str::uuid7(),
                    'user_id' => $user->id,
                    'occurred_on' => $date->format('Y-m-d'),
                    'category' => $expense['category']->value,
                    'description' => '[Demo] '.$expense['description'],
                    'amount' => intdiv($expense['amount'] * $percentage, 100),
                    'created_at' => $timestamp,
                    'updated_at' => $timestamp,
                ];

                if (count($batch) === self::BATCH_SIZE) {
                    ExpenseModel::query()->insert($batch);
                    $batch = [];
                }
            }

            if ($batch !== []) {
                ExpenseModel::query()->insert($batch);
            }
        }
    }

    /** @return list<array{amount: int, category: ExpenseCategoryEnum, description: string}> */
    private function expenseTemplates(): array
    {
        return [
            ['amount' => 160000, 'category' => ExpenseCategoryEnum::Housing, 'description' => 'Aluguel'],
            ['amount' => 42000, 'category' => ExpenseCategoryEnum::Food, 'description' => 'Supermercado'],
            ['amount' => 18000, 'category' => ExpenseCategoryEnum::Transport, 'description' => 'Combustível'],
            ['amount' => 22000, 'category' => ExpenseCategoryEnum::Food, 'description' => 'Feira e mercado'],
            ['amount' => 5900, 'category' => ExpenseCategoryEnum::Subscriptions, 'description' => 'Streaming'],
            ['amount' => 12500, 'category' => ExpenseCategoryEnum::Health, 'description' => 'Farmácia'],
            ['amount' => 18000, 'category' => ExpenseCategoryEnum::Food, 'description' => 'Restaurante'],
            ['amount' => 9900, 'category' => ExpenseCategoryEnum::Health, 'description' => 'Academia'],
            ['amount' => 15000, 'category' => ExpenseCategoryEnum::Housing, 'description' => 'Energia elétrica'],
            ['amount' => 12000, 'category' => ExpenseCategoryEnum::Services, 'description' => 'Internet'],
            ['amount' => 8900, 'category' => ExpenseCategoryEnum::Leisure, 'description' => 'Cinema'],
            ['amount' => 16000, 'category' => ExpenseCategoryEnum::Education, 'description' => 'Curso'],
            ['amount' => 24000, 'category' => ExpenseCategoryEnum::Food, 'description' => 'Compras da semana'],
            ['amount' => 14500, 'category' => ExpenseCategoryEnum::Shopping, 'description' => 'Roupas'],
            ['amount' => 6500, 'category' => ExpenseCategoryEnum::Transport, 'description' => 'Transporte por aplicativo'],
            ['amount' => 11000, 'category' => ExpenseCategoryEnum::Leisure, 'description' => 'Passeio'],
        ];
    }
}
