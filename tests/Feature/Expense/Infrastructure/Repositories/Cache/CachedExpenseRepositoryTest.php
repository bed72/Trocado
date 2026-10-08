<?php

declare(strict_types=1);

use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;
use App\Expense\Infrastructure\Repositories\Cache\CachedExpenseRepository;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

function cachedRepositoryFixture(): array
{
    Cache::tags('expense:pages:owner:1')->flush();
    Cache::tags('expense:pages:owner:2')->flush();

    $inner = new class implements ExpenseRepository
    {
        public int $getAllCalls = 0;

        public int $createCalls = 0;

        public int $deleteCalls = 0;

        public int $updateCalls = 0;

        public function getById(int $id, int $userId): ?ExpenseEntity
        {
            return null;
        }

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

        public function delete(int $id, int $userId): bool
        {
            $this->deleteCalls++;

            return $id === 10 && $userId === 1;
        }

        public function update(int $id, int $userId, UpdateExpenseInput $input): ?ExpenseEntity
        {
            $this->updateCalls++;

            if ($id !== 10 || $userId !== 1) {
                return null;
            }

            return new ExpenseEntity(
                id: $id,
                userId: $userId,
                category: $input->category,
                amount: $input->amount ?? 2000,
                description: $input->description,
                occurredOn: $input->occurredOn ?? '2026-09-24',
            );
        }

        public function getAll(int $userId, int $size, ?string $cursor): ExpensePageOutput
        {
            $this->getAllCalls++;

            return new ExpensePageOutput(
                items: [new ExpenseEntity(
                    id: $this->getAllCalls,
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

    $page = $repository->getAll(userId: 1, size: 20, cursor: null);

    expect($inner->getAllCalls)->toBe(1)
        ->and($page->items)->toHaveCount(1)
        ->and($page->items[0])->toBeInstanceOf(ExpenseEntity::class)
        ->and($page->items[0]->id)->toBe(1)
        ->and($page->nextCursor)->toBe('next');
});

it('serves cache hits without querying the decorated expense repository again', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $first = $repository->getAll(userId: 1, size: 20, cursor: null);
    $second = $repository->getAll(userId: 1, size: 20, cursor: null);

    expect($inner->getAllCalls)->toBe(1)
        ->and($second->items[0]->id)->toBe($first->items[0]->id);
});

it('keeps owner, size, and cursor pages isolated in cache', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $repository->getAll(userId: 1, size: 20, cursor: null);
    $repository->getAll(userId: 2, size: 20, cursor: null);
    $repository->getAll(userId: 1, size: 10, cursor: null);
    $repository->getAll(userId: 1, size: 20, cursor: 'abc');

    expect($inner->getAllCalls)->toBe(4);
});

it('invalidates cached owner pages after creating an expense', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $repository->getAll(userId: 1, size: 20, cursor: null);
    $repository->create(new ExpenseEntity(
        id: null,
        userId: 1,
        amount: 2000,
        occurredOn: '2026-09-24',
    ));
    $repository->getAll(userId: 1, size: 20, cursor: null);

    expect($inner->createCalls)->toBe(1)
        ->and($inner->getAllCalls)->toBe(2);
});

it('invalidates cached owner pages after deleting an expense', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $repository->getAll(userId: 1, size: 20, cursor: null);
    $repository->delete(id: 10, userId: 1);
    $repository->getAll(userId: 1, size: 20, cursor: null);

    expect($inner->deleteCalls)->toBe(1)
        ->and($inner->getAllCalls)->toBe(2);
});

it('keeps cached owner pages when deleting an absent expense', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $repository->getAll(userId: 1, size: 20, cursor: null);
    $repository->delete(id: 99, userId: 1);
    $repository->getAll(userId: 1, size: 20, cursor: null);

    expect($inner->deleteCalls)->toBe(1)
        ->and($inner->getAllCalls)->toBe(1);
});

it('invalidates cached owner pages after updating an expense', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $repository->getAll(userId: 1, size: 20, cursor: null);
    $repository->update(id: 10, userId: 1, input: new UpdateExpenseInput(amount: 3000, hasAmount: true));
    $repository->getAll(userId: 1, size: 20, cursor: null);

    expect($inner->updateCalls)->toBe(1)
        ->and($inner->getAllCalls)->toBe(2);
});

it('keeps cached owner pages when updating an absent expense', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $repository->getAll(userId: 1, size: 20, cursor: null);
    $repository->update(id: 99, userId: 1, input: new UpdateExpenseInput(amount: 3000, hasAmount: true));
    $repository->getAll(userId: 1, size: 20, cursor: null);

    expect($inner->updateCalls)->toBe(1)
        ->and($inner->getAllCalls)->toBe(1);
});

it('implements the expense repository contract', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    expect($repository)->toBeInstanceOf(ExpenseRepository::class)
        ->and($inner)->toBeInstanceOf(ExpenseRepository::class);
});

it('keeps cached pages until the outer creation commits, then invalidates only that owner', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();
    $repository->getAll(userId: 1, size: 20, cursor: null);
    $repository->getAll(userId: 2, size: 20, cursor: null);

    DB::transaction(callback: function () use ($repository, $inner): void {
        DB::transaction(callback: function () use ($repository): void {
            $repository->create(expense: new ExpenseEntity(
                id: null,
                userId: 1,
                amount: 2000,
                occurredOn: '2026-09-24',
            ));
        });

        $repository->getAll(userId: 1, size: 20, cursor: null);
        expect($inner->getAllCalls)->toBe(2);
    });

    $repository->getAll(userId: 1, size: 20, cursor: null);
    $repository->getAll(userId: 2, size: 20, cursor: null);

    expect($inner->getAllCalls)->toBe(3);
});

it('does not invalidate cached pages when a creation rolls back', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();
    $repository->getAll(userId: 1, size: 20, cursor: null);

    try {
        DB::transaction(callback: function () use ($repository): void {
            $repository->create(expense: new ExpenseEntity(
                id: null,
                userId: 1,
                amount: 2000,
                occurredOn: '2026-09-24',
            ));

            throw new RuntimeException('Rollback.');
        });
    } catch (RuntimeException) {
    }

    $repository->getAll(userId: 1, size: 20, cursor: null);

    expect($inner->createCalls)->toBe(1)
        ->and($inner->getAllCalls)->toBe(1);
});

it('does not invalidate on a nested rollback even if the outer transaction commits', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();
    $repository->getAll(userId: 1, size: 20, cursor: null);

    DB::transaction(callback: function () use ($repository): void {
        try {
            DB::transaction(callback: function () use ($repository): void {
                $repository->create(expense: new ExpenseEntity(
                    id: null,
                    userId: 1,
                    amount: 2000,
                    occurredOn: '2026-09-24',
                ));

                throw new RuntimeException('Rollback savepoint.');
            });
        } catch (RuntimeException) {
        }
    });

    $repository->getAll(userId: 1, size: 20, cursor: null);
    expect($inner->getAllCalls)->toBe(1);
});

it('invalidates edited or deleted pages only after the corresponding transaction commits', function (string $operation): void {
    [$inner, $repository] = cachedRepositoryFixture();
    $repository->getAll(userId: 1, size: 20, cursor: null);

    $write = function () use ($repository, $operation): void {
        if ($operation === 'update') {
            $repository->update(id: 10, userId: 1, input: new UpdateExpenseInput(amount: 3000, hasAmount: true));

            return;
        }

        $repository->delete(id: 10, userId: 1);
    };

    try {
        DB::transaction(callback: function () use ($write): void {
            $write();

            throw new RuntimeException('Rollback.');
        });
    } catch (RuntimeException) {
    }

    $repository->getAll(userId: 1, size: 20, cursor: null);
    expect($inner->getAllCalls)->toBe(1);

    DB::transaction(callback: function () use ($write, $repository, $inner): void {
        $write();
        $repository->getAll(userId: 1, size: 20, cursor: null);
        expect($inner->getAllCalls)->toBe(1);
    });

    $repository->getAll(userId: 1, size: 20, cursor: null);
    expect($inner->getAllCalls)->toBe(2);
})->with(['update', 'delete']);
