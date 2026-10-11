<?php

declare(strict_types=1);

use App\Core\Domain\Enums\ExpenseCategoryEnum;
use App\Expense\Application\Data\ApplyExpenseClassificationInput;
use App\Expense\Application\Data\ExpenseClassificationOutput;
use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Data\GetAllExpenseInput;
use App\Expense\Application\Ports\ExpenseQueryCursorPort;
use App\Expense\Application\Repositories\ExpenseCategorizationRepository;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;
use App\Expense\Infrastructure\Repositories\Cache\CachedExpenseCategorizationRepository;
use App\Expense\Infrastructure\Repositories\Cache\CachedExpenseRepository;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Tests\Support\Expense\Fixtures\ExpenseQueryFixture;

function categorizationCacheFixture(int $expectedGetAllCalls): array
{
    Cache::tags('expense:pages:owner:1')->flush();
    Cache::tags('expense:pages:owner:2')->flush();

    $expenses = Mockery::mock(ExpenseRepository::class);
    $expenses->shouldReceive('getAll')->times($expectedGetAllCalls)->andReturnUsing(fn (int $userId, GetAllExpenseInput $input): ExpensePageOutput => new ExpensePageOutput(
        items: [new ExpenseEntity(id: $userId, userId: $userId, amount: 100, category: 'other', occurredOn: '2026-09-24')],
        nextCursor: null,
        previousCursor: null,
    ));

    $attempts = Mockery::mock(ExpenseCategorizationRepository::class);
    $attempts->shouldReceive('beginClassificationAttempt')->andReturn(true);
    $attempts->shouldReceive('findClassificationAttempt')->andReturn(new ExpenseClassificationOutput('Mercado - 2 itens'));
    $attempts->shouldReceive('cancelClassification');
    $attempts->shouldReceive('applyClassificationAttempt')->andReturnUsing(fn (ApplyExpenseClassificationInput $input): ?int => $input->expenseId === 10 ? 1 : null);

    return [
        $expenses,
        new CachedExpenseRepository(port: app(ExpenseQueryCursorPort::class), cache: app('cache'), repository: $expenses),
        new CachedExpenseCategorizationRepository(cache: app('cache'), repository: $attempts),
    ];
}

it('resolves distinct decorated repository contracts', function (): void {
    expect(app(ExpenseRepository::class))->toBeInstanceOf(CachedExpenseRepository::class)
        ->and(app(ExpenseCategorizationRepository::class))->toBeInstanceOf(CachedExpenseCategorizationRepository::class);
});

it('invalidates only the updated owner pages across sizes and cursors after classification', function (): void {
    [, $pages, $attempts] = categorizationCacheFixture(7);

    $pages->getAll(userId: 1, input: ExpenseQueryFixture::input());
    $pages->getAll(userId: 1, input: ExpenseQueryFixture::input(size: 10));
    $pages->getAll(userId: 1, input: ExpenseQueryFixture::input(cursor: ExpenseQueryFixture::legacyCursor()));
    $pages->getAll(userId: 2, input: ExpenseQueryFixture::input());

    $attempts->applyClassificationAttempt(new ApplyExpenseClassificationInput(10, 'token', 'Mercado - 2 itens', ExpenseCategoryEnum::Food));

    $pages->getAll(userId: 1, input: ExpenseQueryFixture::input());
    $pages->getAll(userId: 1, input: ExpenseQueryFixture::input(size: 10));
    $pages->getAll(userId: 1, input: ExpenseQueryFixture::input(cursor: ExpenseQueryFixture::legacyCursor()));
    $pages->getAll(userId: 2, input: ExpenseQueryFixture::input());
});

it('keeps pages for begin, find, cancel, and rejected application', function (): void {
    [, $pages, $attempts] = categorizationCacheFixture(1);

    $pages->getAll(userId: 1, input: ExpenseQueryFixture::input());
    $attempts->beginClassificationAttempt(10, 'token', new DateTimeImmutable('+5 minutes'));
    $attempts->findClassificationAttempt(10, 'token');
    $attempts->cancelClassification(10, 'token');
    $attempts->applyClassificationAttempt(new ApplyExpenseClassificationInput(99, 'token', 'Mercado - 2 itens', ExpenseCategoryEnum::Food));
    $pages->getAll(userId: 1, input: ExpenseQueryFixture::input());
});

it('defers classification invalidation until outer commit and discards it on rollback', function (): void {
    [, $pages, $attempts] = categorizationCacheFixture(2);
    $pages->getAll(userId: 1, input: ExpenseQueryFixture::input());

    try {
        DB::transaction(function () use ($attempts, $pages): void {
            $attempts->applyClassificationAttempt(new ApplyExpenseClassificationInput(10, 'token', 'Mercado - 2 itens', ExpenseCategoryEnum::Food));
            $pages->getAll(userId: 1, input: ExpenseQueryFixture::input());

            throw new RuntimeException('Rollback.');
        });
    } catch (RuntimeException) {
    }

    $pages->getAll(userId: 1, input: ExpenseQueryFixture::input());

    DB::transaction(function () use ($attempts, $pages): void {
        DB::transaction(fn (): ?int => $attempts->applyClassificationAttempt(new ApplyExpenseClassificationInput(10, 'token', 'Mercado - 2 itens', ExpenseCategoryEnum::Food)));

        $pages->getAll(userId: 1, input: ExpenseQueryFixture::input());
    });

    $pages->getAll(userId: 1, input: ExpenseQueryFixture::input());
});
