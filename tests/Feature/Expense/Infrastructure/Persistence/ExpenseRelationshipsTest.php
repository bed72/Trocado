<?php

declare(strict_types=1);

use App\Expense\Application\Data\CreateExpenseInput;
use App\Expense\Application\UseCases\CreateExpenseUseCase;
use App\Expense\Infrastructure\Persistence\Models\ExpenseModel;
use App\Expense\Infrastructure\Providers\ExpenseServiceProvider;
use App\Identity\Infrastructure\Persistence\Models\UserModel;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\LazyLoadingViolationException;
use Illuminate\Support\Facades\DB;

beforeEach(function (): void {
    $firstUser = signUpIdentityByApi($this);
    $secondUser = signUpIdentityByApi($this, name: 'Paulo', email: 'paulo@example.com');
    $useCase = app(CreateExpenseUseCase::class);

    $useCase->execute(new CreateExpenseInput(userId: $firstUser, amount: 100, occurredOn: '2026-09-20'));
    $useCase->execute(new CreateExpenseInput(userId: $secondUser, amount: 200, occurredOn: '2026-09-21'));
});

it('eager loads users with expenses using two queries for multiple owners', function (): void {
    $archivedExpense = app(CreateExpenseUseCase::class)->execute(new CreateExpenseInput(
        userId: (int) UserModel::query()->orderBy('id')->value('id'),
        amount: 300,
        occurredOn: '2026-09-22',
    ));
    ExpenseModel::query()->findOrFail($archivedExpense->id)->delete();

    DB::enableQueryLog();
    DB::flushQueryLog();

    $users = UserModel::query()->with('expenses')->orderBy('id')->get();

    expect($users)->toHaveCount(2)
        ->and($users[0]->relationLoaded('expenses'))->toBeTrue()
        ->and($users[0]->expenses)->toHaveCount(1)
        ->and($users[1]->expenses)->toHaveCount(1)
        ->and(DB::getQueryLog())->toHaveCount(2);
});

it('eager loads expenses with their users using two queries for multiple expenses', function (): void {
    DB::enableQueryLog();
    DB::flushQueryLog();

    $expenses = ExpenseModel::query()->with('user')->orderBy('id')->get();

    expect($expenses)->toHaveCount(2)
        ->and($expenses[0]->relationLoaded('user'))->toBeTrue()
        ->and($expenses[0]->user)->toBeInstanceOf(UserModel::class)
        ->and($expenses[1]->user->id)->not->toBe($expenses[0]->user->id)
        ->and(DB::getQueryLog())->toHaveCount(2);
});

it('rejects lazy loading of expenses from a collection of users', function (): void {
    $users = UserModel::query()->orderBy('id')->get();

    expect(fn () => $users[0]->expenses)->toThrow(LazyLoadingViolationException::class);
});

it('rejects lazy loading of users from a collection of expenses', function (): void {
    $expenses = ExpenseModel::query()->orderBy('id')->get();

    expect(fn () => $expenses[0]->user)->toThrow(LazyLoadingViolationException::class);
});

it('activates N+1 protection when the expense provider boots outside production', function (): void {
    Model::preventLazyLoading(false);

    (new ExpenseServiceProvider(app: app()))->boot();

    expect(Model::preventsLazyLoading())->toBeTrue();
});
