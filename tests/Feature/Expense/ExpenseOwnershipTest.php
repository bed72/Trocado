<?php

declare(strict_types=1);

use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;

use function Pest\Laravel\withToken;

it('lists only expenses owned by the authenticated user', function (): void {
    $firstUserId = signUpIdentityByApi($this, email: 'maria@example.com');
    $firstToken = signInIdentityByApi($this, email: 'maria@example.com');
    $secondUserId = signUpIdentityByApi($this, name: 'Joana', email: 'joana@example.com');

    ExpenseModel::query()->create([
        'user_id' => $firstUserId,
        'amount' => 1000,
        'occurred_on' => '2026-09-24',
        'category' => 'food',
        'description' => 'own',
    ]);
    ExpenseModel::query()->create([
        'user_id' => $secondUserId,
        'amount' => 9999,
        'occurred_on' => '2026-09-24',
        'category' => 'other',
        'description' => 'other',
    ]);

    withToken($firstToken)->getJson(route('expenses.index'))
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.attributes.description', 'own');
});

it('creates expenses for the authenticated user only', function (): void {
    $firstUserId = signUpIdentityByApi($this, email: 'maria@example.com');
    $firstToken = signInIdentityByApi($this, email: 'maria@example.com');
    $secondUserId = signUpIdentityByApi($this, name: 'Joana', email: 'joana@example.com');

    withToken($firstToken)->postJson(route('expenses.create'), [
        'data' => [
            'type' => 'expenses',
            'attributes' => [
                'amount' => 1500,
                'occurred_on' => '2026-09-24',
                'category' => 'food',
                'description' => 'created',
                'user_id' => $secondUserId,
            ],
        ],
    ])->assertUnprocessable();

    expect(ExpenseModel::query()->where('user_id', $secondUserId)->exists())->toBeFalse();

    withToken($firstToken)->postJson(route('expenses.create'), [
        'data' => [
            'type' => 'expenses',
            'attributes' => [
                'amount' => 1500,
                'occurred_on' => '2026-09-24',
                'category' => 'food',
                'description' => 'created',
            ],
        ],
    ])->assertCreated();

    expect(ExpenseModel::query()->where('user_id', $firstUserId)->count())->toBe(1)
        ->and(ExpenseModel::query()->where('user_id', $secondUserId)->exists())->toBeFalse();
});

it('keeps the expenses foreign key and cascade without Eloquent cross-context relations', function (): void {
    $user = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Correct1',
    ]);
    $expense = ExpenseModel::query()->create([
        'user_id' => $user->getKey(),
        'amount' => 1000,
        'occurred_on' => '2026-09-24',
        'category' => 'food',
    ]);

    expect($expense->user_id)->toBe($user->getKey());

    $user->delete();

    expect(ExpenseModel::withTrashed()->whereKey($expense->getKey())->exists())->toBeFalse();
});
