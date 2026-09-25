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
        'amount' => 1000,
        'category' => 'food',
        'description' => 'own',
        'user_id' => $firstUserId,
        'occurred_on' => '2026-09-24',
    ]);
    ExpenseModel::query()->create([
        'amount' => 9999,
        'category' => 'other',
        'description' => 'other',
        'user_id' => $secondUserId,
        'occurred_on' => '2026-09-24',
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
                'category' => 'food',
                'description' => 'created',
                'user_id' => $secondUserId,
                'occurred_on' => '2026-09-24',
            ],
        ],
    ])->assertUnprocessable();

    expect(ExpenseModel::query()->where('user_id', $secondUserId)->exists())->toBeFalse();

    withToken($firstToken)->postJson(route('expenses.create'), [
        'data' => [
            'type' => 'expenses',
            'attributes' => [
                'amount' => 1500,
                'category' => 'food',
                'description' => 'created',
                'occurred_on' => '2026-09-24',
            ],
        ],
    ])->assertCreated();

    expect(ExpenseModel::query()->where('user_id', $firstUserId)->count())->toBe(1)
        ->and(ExpenseModel::query()->where('user_id', $secondUserId)->exists())->toBeFalse();
});

it('deletes expenses for the authenticated user only', function (): void {
    $firstUserId = signUpIdentityByApi($this, email: 'maria@example.com');
    $firstToken = signInIdentityByApi($this, email: 'maria@example.com');
    $secondUserId = signUpIdentityByApi($this, name: 'Joana', email: 'joana@example.com');

    $firstExpense = ExpenseModel::query()->create([
        'amount' => 1000,
        'category' => 'food',
        'description' => 'own',
        'user_id' => $firstUserId,
        'occurred_on' => '2026-09-24',
    ]);
    $secondExpense = ExpenseModel::query()->create([
        'amount' => 9999,
        'category' => 'other',
        'description' => 'other',
        'user_id' => $secondUserId,
        'occurred_on' => '2026-09-24',
    ]);

    withToken($firstToken)->deleteJson(route('expenses.delete', ['expense' => $secondExpense->getKey()]))
        ->assertNotFound();

    expect(ExpenseModel::query()->whereKey($secondExpense->getKey())->exists())->toBeTrue();

    withToken($firstToken)->deleteJson(route('expenses.delete', ['expense' => $firstExpense->getKey()]))
        ->assertNoContent();

    expect(ExpenseModel::query()->whereKey($firstExpense->getKey())->exists())->toBeFalse()
        ->and(ExpenseModel::query()->whereKey($secondExpense->getKey())->exists())->toBeTrue();
});

it('updates expenses for the authenticated user only', function (): void {
    $firstUserId = signUpIdentityByApi($this, email: 'maria@example.com');
    $firstToken = signInIdentityByApi($this, email: 'maria@example.com');
    $secondUserId = signUpIdentityByApi($this, name: 'Joana', email: 'joana@example.com');

    $firstExpense = ExpenseModel::query()->create([
        'amount' => 1000,
        'category' => 'food',
        'description' => 'own',
        'user_id' => $firstUserId,
        'occurred_on' => '2026-09-24',
    ]);
    $secondExpense = ExpenseModel::query()->create([
        'amount' => 9999,
        'category' => 'other',
        'description' => 'other',
        'user_id' => $secondUserId,
        'occurred_on' => '2026-09-24',
    ]);

    withToken($firstToken)->patchJson(route('expenses.update', ['expense' => $secondExpense->getKey()]), [
        'data' => [
            'type' => 'expenses',
            'attributes' => [
                'amount' => 2000,
            ],
        ],
    ])->assertNotFound();

    expect($secondExpense->refresh()->amount)->toBe(9999);

    withToken($firstToken)->patchJson(route('expenses.update', ['expense' => $firstExpense->getKey()]), [
        'data' => [
            'type' => 'expenses',
            'attributes' => [
                'amount' => 2000,
                'description' => null,
            ],
        ],
    ])->assertOk()
        ->assertJsonPath('data.attributes.amount', 2000)
        ->assertJsonPath('data.attributes.description', null);

    $firstExpense->refresh();

    expect($firstExpense->amount)->toBe(2000)
        ->and($firstExpense->description)->toBeNull()
        ->and($firstExpense->occurred_on)->toBe('2026-09-24')
        ->and($secondExpense->refresh()->amount)->toBe(9999);
});

it('keeps the expenses foreign key and cascade without Eloquent cross-context relations', function (): void {
    $user = UserModel::query()->create([
        'name' => 'Maria',
        'password' => 'Correct1',
        'email' => 'maria@example.com',
    ]);
    $expense = ExpenseModel::query()->create([
        'amount' => 1000,
        'category' => 'food',
        'user_id' => $user->getKey(),
        'occurred_on' => '2026-09-24',
    ]);

    expect($expense->user_id)->toBe($user->getKey());

    $user->delete();

    expect(ExpenseModel::withTrashed()->whereKey($expense->getKey())->exists())->toBeFalse();
});
