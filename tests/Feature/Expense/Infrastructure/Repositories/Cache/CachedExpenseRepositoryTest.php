<?php

declare(strict_types=1);

use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;
use App\Expense\Infrastructure\Repositories\Cache\CachedExpenseRepository;
use Illuminate\Support\Facades\Cache;

function cachedRepositoryFixture(): array
{
    Cache::tags('expense:pages:owner:1')->flush();
    Cache::tags('expense:pages:owner:2')->flush();

    $inner = new class implements ExpenseRepository
    {
        public int $listCalls = 0;

        public int $createCalls = 0;

        public function create(ExpenseEntity $expense): ExpenseEntity
        {
            $this->createCalls++;

            return new ExpenseEntity(
                id: 10,
                userId: $expense->userId,
                amount: $expense->amount,
                occurredOn: $expense->occurredOn,
                description: $expense->description,
                category: $expense->category->value,
            );
        }

        public function listByUser(int $userId, int $size, ?string $cursor): ExpensePageOutput
        {
            $this->listCalls++;

            return new ExpensePageOutput(
                items: [new ExpenseEntity(
                    id: $this->listCalls,
                    userId: $userId,
                    amount: 1234,
                    category: 'food',
                    description: $cursor,
                    occurredOn: '2026-09-24',
                )],
                nextCursor: 'next',
                previousCursor: null,
            );
        }
    };

    return [$inner, new CachedExpenseRepository(
        repository: $inner,
        cache: app('cache'),
    )];
}

it('serves cache misses through the decorated expense repository', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $page = $repository->listByUser(userId: 1, size: 20, cursor: null);

    expect($inner->listCalls)->toBe(1)
        ->and($page->items)->toHaveCount(1)
        ->and($page->items[0])->toBeInstanceOf(ExpenseEntity::class)
        ->and($page->items[0]->id)->toBe(1)
        ->and($page->nextCursor)->toBe('next');
});

it('serves cache hits without querying the decorated expense repository again', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $first = $repository->listByUser(userId: 1, size: 20, cursor: null);
    $second = $repository->listByUser(userId: 1, size: 20, cursor: null);

    expect($inner->listCalls)->toBe(1)
        ->and($second->items[0]->id)->toBe($first->items[0]->id);
});

it('keeps owner, size, and cursor pages isolated in cache', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $repository->listByUser(userId: 1, size: 20, cursor: null);
    $repository->listByUser(userId: 2, size: 20, cursor: null);
    $repository->listByUser(userId: 1, size: 10, cursor: null);
    $repository->listByUser(userId: 1, size: 20, cursor: 'abc');

    expect($inner->listCalls)->toBe(4);
});

it('invalidates cached owner pages after creating an expense', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $repository->listByUser(userId: 1, size: 20, cursor: null);
    $repository->create(new ExpenseEntity(
        id: null,
        userId: 1,
        amount: 2000,
        occurredOn: '2026-09-24',
    ));
    $repository->listByUser(userId: 1, size: 20, cursor: null);

    expect($inner->createCalls)->toBe(1)
        ->and($inner->listCalls)->toBe(2);
});

it('implements the expense repository contract', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    expect($repository)->toBeInstanceOf(ExpenseRepository::class)
        ->and($inner)->toBeInstanceOf(ExpenseRepository::class);
});
