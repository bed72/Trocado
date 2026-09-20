<?php

declare(strict_types=1);

use App\Budget\Infrastructure\Persistence\Models\BudgetModel;

beforeEach(function (): void {
    $this->budget = BudgetModel::query()->create([
        'amount' => 12500,
        'start_date' => '2026-09-01',
        'end_date' => '2026-09-30',
    ]);
});

it('updates a zero amount while preserving dates', function (): void {
    $this->patchJson("/api/budgets/{$this->budget->getKey()}", updateBudgetApiPayload(
        id: (int) $this->budget->getKey(),
        attributes: ['amount' => 0],
    ))->assertOk()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('data.attributes.amount', 0)
        ->assertJsonPath('data.attributes.start_date', '2026-09-01')
        ->assertJsonPath('data.attributes.end_date', '2026-09-30');

    $this->assertDatabaseHas('budgets', [
        'id' => $this->budget->getKey(),
        'amount' => 0,
        'start_date' => '2026-09-01 00:00:00',
        'end_date' => '2026-09-30 00:00:00',
    ]);
});

it('updates dates while preserving the amount', function (): void {
    $this->patchJson("/api/budgets/{$this->budget->getKey()}", updateBudgetApiPayload(
        id: (int) $this->budget->getKey(),
        attributes: ['start_date' => '2026-10-01', 'end_date' => '2026-10-31'],
    ))->assertOk()
        ->assertJsonPath('data.attributes.amount', 12500)
        ->assertJsonPath('data.attributes.start_date', '2026-10-01')
        ->assertJsonPath('data.attributes.end_date', '2026-10-31');

    $this->assertDatabaseHas('budgets', [
        'id' => $this->budget->getKey(),
        'amount' => 12500,
        'start_date' => '2026-10-01 00:00:00',
        'end_date' => '2026-10-31 00:00:00',
    ]);
});

it('rejects an invalid resulting range without changing the budget', function (): void {
    $this->patchJson("/api/budgets/{$this->budget->getKey()}", updateBudgetApiPayload(
        id: (int) $this->budget->getKey(),
        attributes: ['end_date' => '2026-08-31'],
    ))->assertUnprocessable()
        ->assertJsonPath('errors.0.status', '422')
        ->assertJsonPath('errors.0.title', 'Dados inválidos');

    $this->assertDatabaseHas('budgets', [
        'id' => $this->budget->getKey(),
        'amount' => 12500,
        'start_date' => '2026-09-01 00:00:00',
        'end_date' => '2026-09-30 00:00:00',
    ]);
});

it('rejects a mismatched resource ID without changing the budget', function (): void {
    $this->patchJson("/api/budgets/{$this->budget->getKey()}", updateBudgetApiPayload(
        id: 99999,
        attributes: ['amount' => 100],
    ))->assertUnprocessable()
        ->assertJsonFragment(['source' => ['pointer' => '/data/id']]);

    $this->assertDatabaseHas('budgets', ['id' => $this->budget->getKey(), 'amount' => 12500]);
});

it('requires at least one known attribute', function (array $attributes, string $pointer): void {
    $this->patchJson("/api/budgets/{$this->budget->getKey()}", updateBudgetApiPayload(
        id: (int) $this->budget->getKey(),
        attributes: $attributes,
    ))->assertUnprocessable()
        ->assertJsonFragment(['source' => ['pointer' => $pointer]]);

    $this->assertDatabaseHas('budgets', ['id' => $this->budget->getKey(), 'amount' => 12500]);
})->with([
    'empty attributes' => [[], '/data/attributes'],
    'unexpected attribute' => [['name' => 'extra'], '/data/attributes'],
    'null amount' => [['amount' => null], '/data/attributes/amount'],
    'numeric string amount' => [['amount' => '100'], '/data/attributes/amount'],
    'invalid start date' => [['start_date' => '2026-02-30'], '/data/attributes/start_date'],
]);

it('returns a JSON API error when the budget does not exist', function (): void {
    $this->patchJson('/api/budgets/99999', updateBudgetApiPayload(
        id: 99999,
        attributes: ['amount' => 100],
    ))->assertNotFound()
        ->assertExactJson(['errors' => [[
            'status' => '404',
            'title' => 'Budget não encontrado',
            'detail' => 'Budget 99999 não encontrado.',
        ]]]);
});

function updateBudgetApiPayload(int $id, array $attributes): array
{
    return [
        'data' => [
            'type' => 'budgets',
            'id' => (string) $id,
            'attributes' => $attributes,
        ],
    ];
}
