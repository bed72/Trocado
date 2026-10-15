<?php

declare(strict_types=1);

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Data\GetAllExpenseInput;
use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Application\Ports\ExpenseQueryCursorPort;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;
use App\Expense\Infrastructure\Repositories\Cache\CachedExpenseRepository;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Expense\Fixtures\ExpenseQueryFixture;

function cachedRepositoryFixture(): array
{
    Cache::tags('expense:pages:v3:owner:'.UuidFixture::at(1))->flush();
    Cache::tags('expense:pages:v3:owner:'.UuidFixture::at(2))->flush();

    $inner = new class implements ExpenseRepository
    {
        public int $getAllCalls = 0;

        public int $createCalls = 0;

        public int $deleteCalls = 0;

        public int $updateCalls = 0;

        public function getById(string $id, string $userId): ?ExpenseEntity
        {
            return null;
        }

        public function create(ExpenseEntity $expense): ExpenseEntity
        {
            $this->createCalls++;

            return new ExpenseEntity(
                id: UuidFixture::at(10),
                userId: $expense->userId,
                amount: $expense->amount,
                occurredOn: $expense->occurredOn,
                description: $expense->description,
                category: $expense->category->value,
            );
        }

        public function delete(string $id, string $userId): bool
        {
            $this->deleteCalls++;

            return $id === UuidFixture::at(10) && $userId === UuidFixture::at(1);
        }

        public function update(string $id, string $userId, UpdateExpenseInput $input): ?ExpenseEntity
        {
            $this->updateCalls++;

            if ($id !== UuidFixture::at(10) || $userId !== UuidFixture::at(1)) {
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

        public function getAll(string $userId, GetAllExpenseInput $input): ExpensePageOutput
        {
            $this->getAllCalls++;

            return new ExpensePageOutput(
                items: [new ExpenseEntity(
                    id: UuidFixture::at($this->getAllCalls),
                    userId: $userId,
                    amount: 1234,
                    category: 'food',
                    description: null,
                    occurredOn: '2026-09-24',
                )],
                nextCursor: 'next',
                previousCursor: null,
            );
        }
    };

    return [$inner, new CachedExpenseRepository(
        port: app(ExpenseQueryCursorPort::class),
        repository: $inner,
        cache: app('cache'),
    )];
}

it('serves cache misses through the decorated expense repository', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $page = $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());

    expect($inner->getAllCalls)->toBe(1)
        ->and($page->items)->toHaveCount(1)
        ->and($page->items[0])->toBeInstanceOf(ExpenseEntity::class)
        ->and($page->items[0]->id)->toBe(UuidFixture::at(1))
        ->and($page->nextCursor)->toBe('next');
});

it('serves cache hits without querying the decorated expense repository again', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $first = $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());
    $second = $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());

    expect($inner->getAllCalls)->toBe(1)
        ->and($second->items[0]->id)->toBe($first->items[0]->id);
});

it('keeps owner, size, and cursor pages isolated in cache', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());
    $repository->getAll(userId: UuidFixture::at(2), input: ExpenseQueryFixture::input());
    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input(size: 10));
    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input(cursor: ExpenseQueryFixture::cursor()));

    expect($inner->getAllCalls)->toBe(4);
});

it('isolates periods from unfiltered pages and forwards their inclusive bounds', function (): void {
    $year = DatePeriodValueObject::fromDates('2026-01-01', '2026-12-31');
    $month = DatePeriodValueObject::fromDates('2026-10-01', '2026-10-31');
    $day = DatePeriodValueObject::fromDates('2026-10-11', '2026-10-11');
    $inner = $this->createMock(ExpenseRepository::class);
    $received = [];
    $inner->expects($this->exactly(4))->method('getAll')
        ->willReturnCallback(function (string $userId, GetAllExpenseInput $input) use (&$received): ExpensePageOutput {
            expect($userId)->toBe(UuidFixture::at(1))->and($input->size)->toBe(6)->and($input->cursor)->toBeNull();
            $received[] = $input->from === null ? null : [$input->from, $input->to];

            return new ExpensePageOutput(items: [], nextCursor: null, previousCursor: null);
        });
    $repository = new CachedExpenseRepository(port: app(ExpenseQueryCursorPort::class), cache: app('cache'), repository: $inner);

    foreach ([null, $year, $month, $day] as $period) {
        $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input(size: 6, period: $period));
        $equivalent = $period === null ? null : DatePeriodValueObject::fromDates($period->from(), $period->to());
        $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input(size: 6, period: $equivalent));
    }

    expect($received)->toBe([null, ['2026-01-01', '2026-12-31'], ['2026-10-01', '2026-10-31'], ['2026-10-11', '2026-10-11']]);
});

it('invalidates filtered and unfiltered owner pages after a confirmed mutation', function (string $operation): void {
    [$inner, $repository] = cachedRepositoryFixture();
    $periods = [null, DatePeriodValueObject::monthContaining('2026-10-11')];

    foreach ($periods as $period) {
        $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input(size: 6, period: $period));
        $repository->getAll(userId: UuidFixture::at(2), input: ExpenseQueryFixture::input(size: 6, period: $period));
    }

    if ($operation === 'create') {
        $repository->create(new ExpenseEntity(id: null, userId: UuidFixture::at(1), amount: 2000, occurredOn: '2026-10-11'));
    } elseif ($operation === 'delete') {
        $repository->delete(id: UuidFixture::at(10), userId: UuidFixture::at(1));
    } else {
        $repository->update(id: UuidFixture::at(10), userId: UuidFixture::at(1), input: new UpdateExpenseInput(hasAmount: true, amount: 3000));
    }

    foreach ($periods as $period) {
        $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input(size: 6, period: $period));
        $repository->getAll(userId: UuidFixture::at(2), input: ExpenseQueryFixture::input(size: 6, period: $period));
    }

    expect($inner->getAllCalls)->toBe(6);
})->with(['create', 'delete', 'update']);

it('invalidates cached owner pages after creating an expense', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());
    $repository->create(new ExpenseEntity(
        id: null,
        userId: UuidFixture::at(1),
        amount: 2000,
        occurredOn: '2026-09-24',
    ));
    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());

    expect($inner->createCalls)->toBe(1)
        ->and($inner->getAllCalls)->toBe(2);
});

it('invalidates cached owner pages after deleting an expense', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());
    $repository->delete(id: UuidFixture::at(10), userId: UuidFixture::at(1));
    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());

    expect($inner->deleteCalls)->toBe(1)
        ->and($inner->getAllCalls)->toBe(2);
});

it('keeps cached owner pages when deleting an absent expense', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());
    $repository->delete(id: UuidFixture::at(99), userId: UuidFixture::at(1));
    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());

    expect($inner->deleteCalls)->toBe(1)
        ->and($inner->getAllCalls)->toBe(1);
});

it('invalidates cached owner pages after updating an expense', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());
    $repository->update(id: UuidFixture::at(10), userId: UuidFixture::at(1), input: new UpdateExpenseInput(amount: 3000, hasAmount: true));
    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());

    expect($inner->updateCalls)->toBe(1)
        ->and($inner->getAllCalls)->toBe(2);
});

it('keeps cached owner pages when updating an absent expense', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();

    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());
    $repository->update(id: UuidFixture::at(99), userId: UuidFixture::at(1), input: new UpdateExpenseInput(amount: 3000, hasAmount: true));
    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());

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
    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());
    $repository->getAll(userId: UuidFixture::at(2), input: ExpenseQueryFixture::input());

    DB::transaction(callback: function () use ($repository, $inner): void {
        DB::transaction(callback: function () use ($repository): void {
            $repository->create(expense: new ExpenseEntity(
                id: null,
                userId: UuidFixture::at(1),
                amount: 2000,
                occurredOn: '2026-09-24',
            ));
        });

        $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());
        expect($inner->getAllCalls)->toBe(2);
    });

    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());
    $repository->getAll(userId: UuidFixture::at(2), input: ExpenseQueryFixture::input());

    expect($inner->getAllCalls)->toBe(3);
});

it('does not invalidate cached pages when a creation rolls back', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();
    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());

    try {
        DB::transaction(callback: function () use ($repository): void {
            $repository->create(expense: new ExpenseEntity(
                id: null,
                userId: UuidFixture::at(1),
                amount: 2000,
                occurredOn: '2026-09-24',
            ));

            throw new RuntimeException('Rollback.');
        });
    } catch (RuntimeException) {
    }

    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());

    expect($inner->createCalls)->toBe(1)
        ->and($inner->getAllCalls)->toBe(1);
});

it('does not invalidate on a nested rollback even if the outer transaction commits', function (): void {
    [$inner, $repository] = cachedRepositoryFixture();
    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());

    DB::transaction(callback: function () use ($repository): void {
        try {
            DB::transaction(callback: function () use ($repository): void {
                $repository->create(expense: new ExpenseEntity(
                    id: null,
                    userId: UuidFixture::at(1),
                    amount: 2000,
                    occurredOn: '2026-09-24',
                ));

                throw new RuntimeException('Rollback savepoint.');
            });
        } catch (RuntimeException) {
        }
    });

    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());
    expect($inner->getAllCalls)->toBe(1);
});

it('invalidates edited or deleted pages only after the corresponding transaction commits', function (string $operation): void {
    [$inner, $repository] = cachedRepositoryFixture();
    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());

    $write = function () use ($repository, $operation): void {
        if ($operation === 'update') {
            $repository->update(id: UuidFixture::at(10), userId: UuidFixture::at(1), input: new UpdateExpenseInput(amount: 3000, hasAmount: true));

            return;
        }

        $repository->delete(id: UuidFixture::at(10), userId: UuidFixture::at(1));
    };

    try {
        DB::transaction(callback: function () use ($write): void {
            $write();

            throw new RuntimeException('Rollback.');
        });
    } catch (RuntimeException) {
    }

    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());
    expect($inner->getAllCalls)->toBe(1);

    DB::transaction(callback: function () use ($write, $repository, $inner): void {
        $write();
        $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());
        expect($inner->getAllCalls)->toBe(1);
    });

    $repository->getAll(userId: UuidFixture::at(1), input: ExpenseQueryFixture::input());
    expect($inner->getAllCalls)->toBe(2);
})->with(['update', 'delete']);
