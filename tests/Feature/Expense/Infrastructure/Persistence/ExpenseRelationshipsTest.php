<?php

declare(strict_types=1);

use App\Core\Application\Ports\ScopePort;
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
    $firstUserId = (int) UserModel::query()->orderBy('id')->value('id');
    $archivedExpense = app(CreateExpenseUseCase::class)->execute(new CreateExpenseInput(
        userId: $firstUserId,
        amount: 300,
        occurredOn: '2026-09-22',
    ));
    app(ScopePort::class)->execute($firstUserId, fn () => ExpenseModel::query()->findOrFail($archivedExpense->id)->delete());

    DB::enableQueryLog();
    DB::flushQueryLog();

    $users = app(ScopePort::class)->execute($firstUserId, fn () => UserModel::query()->with('expenses')->orderBy('id')->get());

    expect($users)->toHaveCount(2)
        ->and($users[0]->relationLoaded('expenses'))->toBeTrue()
        ->and($users[0]->expenses)->toHaveCount(1)
        ->and($users[1]->expenses)->toHaveCount(0)
        ->and(array_filter(DB::getQueryLog(), fn (array $query): bool => ! str_contains($query['query'], 'set_config')))->toHaveCount(2);
});

it('eager loads expenses with their users using two queries for multiple expenses', function (): void {
    $firstUserId = (int) UserModel::query()->orderBy('id')->value('id');
    app(CreateExpenseUseCase::class)->execute(new CreateExpenseInput($firstUserId, 300, '2026-09-22'));
    DB::enableQueryLog();
    DB::flushQueryLog();

    $expenses = app(ScopePort::class)->execute($firstUserId, fn () => ExpenseModel::query()->with('user')->orderBy('id')->get());

    expect($expenses)->toHaveCount(2)
        ->and($expenses[0]->relationLoaded('user'))->toBeTrue()
        ->and($expenses[0]->user)->toBeInstanceOf(UserModel::class)
        ->and($expenses[1]->user->id)->toBe($expenses[0]->user->id)
        ->and(array_filter(DB::getQueryLog(), fn (array $query): bool => ! str_contains($query['query'], 'set_config')))->toHaveCount(2);
});

it('rejects lazy loading of expenses from a collection of users', function (): void {
    $users = UserModel::query()->orderBy('id')->get();

    expect(fn () => $users[0]->expenses)->toThrow(LazyLoadingViolationException::class);
});

it('rejects lazy loading of users from a collection of expenses', function (): void {
    $firstUserId = (int) UserModel::query()->orderBy('id')->value('id');
    app(CreateExpenseUseCase::class)->execute(new CreateExpenseInput($firstUserId, 300, '2026-09-22'));
    $expenses = app(ScopePort::class)->execute($firstUserId, fn () => ExpenseModel::query()->orderBy('id')->get());

    expect(fn () => $expenses[0]->user)->toThrow(LazyLoadingViolationException::class);
});

it('activates N+1 protection when the expense provider boots outside production', function (): void {
    Model::preventLazyLoading(false);

    (new ExpenseServiceProvider(app: app()))->boot();

    expect(Model::preventsLazyLoading())->toBeTrue();
});
