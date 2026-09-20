<?php

declare(strict_types=1);

use App\Budget\Infrastructure\Persistence\Models\BudgetModel;

it('returns the requested budget as a complete JSON API resource', function (): void {
    $budget = BudgetModel::query()->create([
        'amount' => 12500,
        'start_date' => '2026-09-01',
        'end_date' => '2026-09-30',
    ]);

    $this->getJson("/api/budgets/{$budget->getKey()}")
        ->assertOk()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('data.id', (string) $budget->getKey())
        ->assertJsonPath('data.type', 'budgets')
        ->assertJsonPath('data.attributes.amount', 12500)
        ->assertJsonPath('data.attributes.start_date', '2026-09-01')
        ->assertJsonPath('data.attributes.end_date', '2026-09-30')
        ->assertJsonPath('data.links.self', route('budgets.get', ['budget' => $budget->getKey()]));
});

it('returns a complete JSON API error when the budget does not exist', function (): void {
    $this->getJson('/api/budgets/99999')
        ->assertNotFound()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '404',
            'title' => 'Budget não encontrado',
            'detail' => 'Budget 99999 não encontrado.',
        ]]]);
});

it('returns a route level JSON API error for a non numeric ID', function (): void {
    $this->getJson('/api/budgets/not-a-number')
        ->assertNotFound()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '404',
            'title' => 'Recurso não encontrado',
            'detail' => 'O recurso solicitado não foi encontrado.',
        ]]]);
});
