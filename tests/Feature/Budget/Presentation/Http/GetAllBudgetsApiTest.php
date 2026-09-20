<?php

declare(strict_types=1);

use App\Budget\Infrastructure\Persistence\Models\BudgetModel;

it('returns an empty JSON API collection', function (): void {
    $this->getJson(route('budgets.get-all'))
        ->assertOk()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['data' => []]);
});

it('lists budgets in ID order', function (): void {
    $first = BudgetModel::query()->create([
        'amount' => 12500,
        'start_date' => '2026-09-01',
        'end_date' => '2026-09-30',
    ]);
    $second = BudgetModel::query()->create([
        'amount' => 25000,
        'start_date' => '2026-10-01',
        'end_date' => '2026-10-31',
    ]);

    $this->getJson(route('budgets.get-all'))
        ->assertOk()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonCount(2, 'data')
        ->assertJsonPath('data.0.id', (string) $first->getKey())
        ->assertJsonPath('data.0.attributes.amount', 12500)
        ->assertJsonPath('data.1.id', (string) $second->getKey())
        ->assertJsonPath('data.1.attributes.amount', 25000);
});
