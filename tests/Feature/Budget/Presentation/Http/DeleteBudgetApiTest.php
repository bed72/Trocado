<?php

declare(strict_types=1);

use App\Budget\Infrastructure\Persistence\Models\BudgetModel;
use App\User\Infrastructure\Persistence\Models\UserModel;
use Laravel\Sanctum\Sanctum;

beforeEach(function (): void {
    Sanctum::actingAs(new UserModel);
});

it('deletes a budget and it can no longer be retrieved', function (): void {
    $budget = BudgetModel::query()->create([
        'amount' => 12500,
        'start_date' => '2026-09-01',
        'end_date' => '2026-09-30',
    ]);

    $this->deleteJson("/api/budgets/{$budget->getKey()}")->assertNoContent();

    $this->assertDatabaseMissing('budgets', ['id' => $budget->getKey()]);
    $this->getJson("/api/budgets/{$budget->getKey()}")
        ->assertNotFound()
        ->assertJsonPath('errors.0.status', '404');
});

it('returns a complete JSON API error when the budget does not exist', function (): void {
    $this->deleteJson('/api/budgets/99999')
        ->assertNotFound()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '404',
            'title' => 'Budget não encontrado',
            'detail' => 'Budget 99999 não encontrado.',
        ]]]);
});

it('returns a route level JSON API error for a non numeric ID', function (): void {
    $this->deleteJson('/api/budgets/not-a-number')
        ->assertNotFound()
        ->assertExactJson(['errors' => [[
            'status' => '404',
            'title' => 'Recurso não encontrado',
            'detail' => 'O recurso solicitado não foi encontrado.',
        ]]]);
});
