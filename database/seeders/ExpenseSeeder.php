<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Expense\Domain\Enums\ExpenseCategoryEnum;
use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Carbon\CarbonImmutable;
use Illuminate\Database\Seeder;

final class ExpenseSeeder extends Seeder
{
    public function run(): void
    {
        $user = UserModel::query()->where('email', 'developer.bed@gmail.com')->firstOrFail();
        $today = CarbonImmutable::today(config('app.timezone'));
        $currentMonth = $today->startOfMonth();

        for ($monthsAgo = 5; $monthsAgo >= 0; $monthsAgo--) {
            $month = $currentMonth->subMonths($monthsAgo);
            $percentage = $monthsAgo === 0 ? 135 : 100;

            foreach ($this->monthlyExpenses() as $expense) {
                $date = $month->addDays($expense['day'] - 1);

                if ($date->greaterThan($today)) {
                    continue;
                }

                ExpenseModel::query()->firstOrCreate([
                    'user_id' => $user->id,
                    'occurred_on' => $date->format('Y-m-d'),
                    'category' => $expense['category']->value,
                    'description' => '[Demo] '.$expense['description'],
                ], [
                    'amount' => intdiv($expense['amount'] * $percentage, 100),
                ]);
            }
        }
    }

    /** @return list<array{day: int, amount: int, category: ExpenseCategoryEnum, description: string}> */
    private function monthlyExpenses(): array
    {
        return [
            ['day' => 1, 'amount' => 160000, 'category' => ExpenseCategoryEnum::Housing, 'description' => 'Aluguel'],
            ['day' => 2, 'amount' => 42000, 'category' => ExpenseCategoryEnum::Food, 'description' => 'Supermercado'],
            ['day' => 3, 'amount' => 18000, 'category' => ExpenseCategoryEnum::Transport, 'description' => 'Combustível'],
            ['day' => 4, 'amount' => 22000, 'category' => ExpenseCategoryEnum::Food, 'description' => 'Feira e mercado'],
            ['day' => 5, 'amount' => 5900, 'category' => ExpenseCategoryEnum::Subscriptions, 'description' => 'Streaming'],
            ['day' => 6, 'amount' => 12500, 'category' => ExpenseCategoryEnum::Health, 'description' => 'Farmácia'],
            ['day' => 7, 'amount' => 18000, 'category' => ExpenseCategoryEnum::Food, 'description' => 'Restaurante'],
            ['day' => 8, 'amount' => 9900, 'category' => ExpenseCategoryEnum::Health, 'description' => 'Academia'],
            ['day' => 12, 'amount' => 15000, 'category' => ExpenseCategoryEnum::Housing, 'description' => 'Energia elétrica'],
            ['day' => 14, 'amount' => 12000, 'category' => ExpenseCategoryEnum::Services, 'description' => 'Internet'],
            ['day' => 16, 'amount' => 8900, 'category' => ExpenseCategoryEnum::Leisure, 'description' => 'Cinema'],
            ['day' => 18, 'amount' => 16000, 'category' => ExpenseCategoryEnum::Education, 'description' => 'Curso'],
            ['day' => 20, 'amount' => 24000, 'category' => ExpenseCategoryEnum::Food, 'description' => 'Compras da semana'],
            ['day' => 22, 'amount' => 14500, 'category' => ExpenseCategoryEnum::Shopping, 'description' => 'Roupas'],
            ['day' => 24, 'amount' => 6500, 'category' => ExpenseCategoryEnum::Transport, 'description' => 'Transporte por aplicativo'],
            ['day' => 26, 'amount' => 11000, 'category' => ExpenseCategoryEnum::Leisure, 'description' => 'Passeio'],
        ];
    }
}
