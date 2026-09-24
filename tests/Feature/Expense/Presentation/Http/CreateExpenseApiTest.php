<?php

declare(strict_types=1);

use App\Expense\Application\Data\CreateExpenseInput;
use App\Expense\Application\Exceptions\ExpenseOwnerNotFoundException;
use App\Expense\Application\UseCases\CreateExpenseUseCase;
use Illuminate\Support\Facades\DB;

it('creates an expense without a budget using the authenticated owner and defaults', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $response = $this->withToken($token)->postJson('/api/expenses', [
        'data' => ['type' => 'expenses', 'attributes' => ['amount' => 1250]],
    ])->assertCreated()->assertHeader('Content-Type', 'application/vnd.api+json');

    expect($response->json('data.type'))->toBe('expenses')
        ->and($response->json('data.id'))->toBeString()
        ->and($response->json('data.attributes'))->toMatchArray([
            'amount' => 1250,
            'category' => 'other',
            'description' => null,
            'occurred_on' => now(config('app.timezone'))->toDateString(),
        ])
        ->and($response->json('data.attributes.created_at'))->toBeString();

    $this->assertDatabaseHas('expenses', [
        'id' => $response->json('data.id'),
        'user_id' => $userId,
        'amount' => 1250,
        'category' => 'other',
        'description' => null,
        'deleted_at' => null,
    ]);
    $this->assertDatabaseCount('budgets', 0);
});

it('uses a chosen category and date', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $this->withToken($token)->postJson('/api/expenses', [
        'data' => ['type' => 'expenses', 'attributes' => [
            'amount' => 1250,
            'occurred_on' => '2026-09-20',
            'category' => 'transport',
            'description' => 'Ônibus',
        ]],
    ])->assertCreated()->assertJsonPath('data.attributes.category', 'transport');

    $this->assertDatabaseHas('expenses', [
        'user_id' => $userId,
        'category' => 'transport',
        'description' => 'Ônibus',
        'occurred_on' => '2026-09-20',
    ]);
});

it('rejects unauthenticated expense creation', function (): void {
    $this->postJson('/api/expenses', ['data' => ['type' => 'expenses', 'attributes' => ['amount' => 1250]]])
        ->assertUnauthorized();

    $this->assertDatabaseCount('expenses', 0);
});

it('rejects invalid attributes and arbitrary ownership', function (array $attributes): void {
    signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $this->withToken($token)->postJson('/api/expenses', [
        'data' => ['type' => 'expenses', 'attributes' => $attributes],
    ])->assertUnprocessable()->assertHeader('Content-Type', 'application/vnd.api+json');

    $this->assertDatabaseCount('expenses', 0);
})->with([
    'zero' => [['amount' => 0]],
    'fractional' => [['amount' => 12.5]],
    'other owner' => [['amount' => 1250, 'user_id' => 999]],
    'unknown category' => [['amount' => 1250, 'category' => 'unknown']],
    'invalid date' => [['amount' => 1250, 'occurred_on' => '2026-02-30']],
    'long description' => [['amount' => 1250, 'description' => str_repeat('a', 65)]],
]);

it('rejects a removed owner through the use case', function (): void {
    $useCase = app(CreateExpenseUseCase::class);

    expect(fn () => $useCase->execute(new CreateExpenseInput(userId: 999, amount: 1250, occurredOn: '2026-09-20')))
        ->toThrow(ExpenseOwnerNotFoundException::class);

    $this->assertDatabaseCount('expenses', 0);
});

it('cascades both active and soft deleted expenses with the owner and rolls back together', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $useCase = app(CreateExpenseUseCase::class);

    $active = $useCase->execute(new CreateExpenseInput(userId: $userId, amount: 1250, occurredOn: '2026-09-20'));
    $deleted = $useCase->execute(new CreateExpenseInput(userId: $userId, amount: 500, occurredOn: '2026-09-21'));
    DB::table('expenses')->where('id', $deleted->id)->update(['deleted_at' => now()]);

    try {
        DB::transaction(function () use ($userId): void {
            DB::table('users')->where('id', $userId)->delete();

            throw new RuntimeException('rollback');
        });
    } catch (RuntimeException $exception) {
        expect($exception->getMessage())->toBe('rollback');
    }

    $this->assertDatabaseHas('expenses', ['id' => $active->id, 'user_id' => $userId]);
    $this->assertDatabaseHas('expenses', ['id' => $deleted->id, 'user_id' => $userId]);

    $this->withToken($token)->deleteJson("/api/users/{$userId}")->assertNoContent();

    $this->assertDatabaseCount('expenses', 0);
    $this->assertDatabaseCount('personal_access_tokens', 0);
});
