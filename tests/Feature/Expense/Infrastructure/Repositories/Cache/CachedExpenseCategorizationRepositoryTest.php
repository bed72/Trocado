<?php

declare(strict_types=1);

use App\Expense\Application\Data\ApplyExpenseClassificationInput;
use App\Expense\Application\Data\ExpenseClassificationOutput;
use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Repositories\ExpenseCategorizationRepository;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;
use App\Expense\Domain\Enums\ExpenseCategoryEnum;
use App\Expense\Infrastructure\Repositories\Cache\CachedExpenseCategorizationRepository;
use App\Expense\Infrastructure\Repositories\Cache\CachedExpenseRepository;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

function categorizationCacheFixture(int $expectedListCalls): array
{
    Cache::tags('expense:pages:owner:1')->flush();
    Cache::tags('expense:pages:owner:2')->flush();

    $expenses = Mockery::mock(ExpenseRepository::class);
    $expenses->shouldReceive('listByUser')->times($expectedListCalls)->andReturnUsing(function (int $userId, int $size, ?string $cursor): ExpensePageOutput {
        return new ExpensePageOutput(
            items: [new ExpenseEntity(id: $userId, userId: $userId, amount: 100, category: 'other', occurredOn: '2026-09-24')],
            nextCursor: null,
            previousCursor: null,
        );
    });

    $attempts = Mockery::mock(ExpenseCategorizationRepository::class);
    $attempts->shouldReceive('beginClassificationAttempt')->andReturn(true);
    $attempts->shouldReceive('findClassificationAttempt')->andReturn(new ExpenseClassificationOutput('Mercado - 2 itens'));
    $attempts->shouldReceive('cancelClassification');
    $attempts->shouldReceive('applyClassificationAttempt')->andReturnUsing(fn (ApplyExpenseClassificationInput $input): ?int => $input->expenseId === 10 ? 1 : null);

    return [
        $expenses,
        new CachedExpenseRepository(cache: app('cache'), repository: $expenses),
        new CachedExpenseCategorizationRepository(cache: app('cache'), repository: $attempts),
    ];
}

it('resolves distinct decorated repository contracts', function (): void {
    expect(app(ExpenseRepository::class))->toBeInstanceOf(CachedExpenseRepository::class)
        ->and(app(ExpenseCategorizationRepository::class))->toBeInstanceOf(CachedExpenseCategorizationRepository::class);
});

it('invalidates only the updated owner pages across sizes and cursors after classification', function (): void {
    [, $pages, $attempts] = categorizationCacheFixture(7);

    $pages->listByUser(userId: 1, size: 20, cursor: null);
    $pages->listByUser(userId: 1, size: 10, cursor: null);
    $pages->listByUser(userId: 1, size: 20, cursor: 'next');
    $pages->listByUser(userId: 2, size: 20, cursor: null);

    $attempts->applyClassificationAttempt(new ApplyExpenseClassificationInput(10, 'token', 'Mercado - 2 itens', ExpenseCategoryEnum::Food));

    $pages->listByUser(userId: 1, size: 20, cursor: null);
    $pages->listByUser(userId: 1, size: 10, cursor: null);
    $pages->listByUser(userId: 1, size: 20, cursor: 'next');
    $pages->listByUser(userId: 2, size: 20, cursor: null);
});

it('keeps pages for begin, find, cancel, and rejected application', function (): void {
    [, $pages, $attempts] = categorizationCacheFixture(1);

    $pages->listByUser(userId: 1, size: 20, cursor: null);
    $attempts->beginClassificationAttempt(10, 'token', new DateTimeImmutable('+5 minutes'));
    $attempts->findClassificationAttempt(10, 'token');
    $attempts->cancelClassification(10, 'token');
    $attempts->applyClassificationAttempt(new ApplyExpenseClassificationInput(99, 'token', 'Mercado - 2 itens', ExpenseCategoryEnum::Food));
    $pages->listByUser(userId: 1, size: 20, cursor: null);
});

it('defers classification invalidation until outer commit and discards it on rollback', function (): void {
    [, $pages, $attempts] = categorizationCacheFixture(2);
    $pages->listByUser(userId: 1, size: 20, cursor: null);

    try {
        DB::transaction(function () use ($attempts, $pages): void {
            $attempts->applyClassificationAttempt(new ApplyExpenseClassificationInput(10, 'token', 'Mercado - 2 itens', ExpenseCategoryEnum::Food));
            $pages->listByUser(userId: 1, size: 20, cursor: null);

            throw new RuntimeException('Rollback.');
        });
    } catch (RuntimeException) {
    }

    $pages->listByUser(userId: 1, size: 20, cursor: null);

    DB::transaction(function () use ($attempts, $pages): void {
        DB::transaction(function () use ($attempts): void {
            $attempts->applyClassificationAttempt(new ApplyExpenseClassificationInput(10, 'token', 'Mercado - 2 itens', ExpenseCategoryEnum::Food));
        });

        $pages->listByUser(userId: 1, size: 20, cursor: null);
    });

    $pages->listByUser(userId: 1, size: 20, cursor: null);
});
