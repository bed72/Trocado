<?php

declare(strict_types=1);

namespace Tests\Support\Expense\Fixtures;

use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Data\GetAllExpenseInput;
use App\Expense\Application\Ports\ExpenseQueryCursorPort;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Infrastructure\Repositories\Persistence\EloquentExpenseRepository;
use Illuminate\Cache\Events\CacheMissed;
use Illuminate\Database\Events\QueryExecuted;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use RuntimeException;
use Tests\Support\Core\Fixtures\UuidFixture;

final class ExpenseCacheContentionFixture
{
    public static function digest(ExpensePageOutput $page): string
    {
        $items = [];
        foreach ($page->items as $item) {
            $values = get_object_vars($item);
            $values['createdAt'] = $item->createdAt?->format('Y-m-d\TH:i:s.uP');
            $items[] = $values;
        }

        return hash('sha256', serialize([$items, $page->nextCursor, $page->previousCursor]));
    }

    public static function key(string $owner, GetAllExpenseInput $input): string
    {
        $cursor = $input->cursor === null ? 'none' : 'cursor:'.$input->cursor;

        return 'expense:pages:v3:'.$owner.':'.$input->size.':'.app(ExpenseQueryCursorPort::class)->fingerprint($input).':'.hash('sha256', $cursor);
    }

    public static function await(string $key, mixed $expected): void
    {
        $deadline = hrtime(true) + 3_000_000_000;
        do {
            if (Cache::get($key) === $expected) {
                return;
            }
            usleep(1000);
        } while (hrtime(true) < $deadline);

        throw new RuntimeException('Cache contention signal timed out: '.$key);
    }

    public static function reader(string $owner, GetAllExpenseInput $input, string $mode, string $signals, string $reader): void
    {
        $key = self::key($owner, $input);
        $tagged = Cache::tags('expense:pages:v3:owner:'.$owner);
        $repository = app(ExpenseRepository::class);
        $signaled = false;
        $start = null;
        $queries = 0;
        $sqlMilliseconds = 0.0;
        $waitMilliseconds = 0.0;
        Event::listen(CacheMissed::class, static function (CacheMissed $event) use ($key, $signals, $reader, &$signaled, &$start): void {
            if ($event->key !== $key || $signaled) {
                return;
            }
            $signaled = true;
            Cache::put($signals.':miss:'.$reader, true, 30);
            self::await($signals.':release', true);
            $start = hrtime(true);
        });
        DB::listen(static function (QueryExecuted $event) use (&$queries, &$sqlMilliseconds): void {
            if (str_contains($event->sql, 'from "expenses"')) {
                $queries++;
                $sqlMilliseconds += $event->time;
            }
        });

        if ($mode === 'original') {
            $page = $repository->getAll($owner, $input);
        } else {
            if ($tagged->get($key) !== null) {
                throw new RuntimeException('The contention probe requires an observed miss.');
            }
            $lock = Cache::lock('step8:page:'.hash('sha256', $key), 2);
            if ($mode === 'lock-5ms') {
                $lock->betweenBlockedAttemptsSleepFor(5);
            }
            $waiting = hrtime(true);
            $page = $lock->block(1, static function () use ($repository, $owner, $input, $waiting, &$waitMilliseconds): ExpensePageOutput {
                $waitMilliseconds = (hrtime(true) - $waiting) / 1e6;

                return $repository->getAll($owner, $input);
            });
        }
        if ($start === null) {
            throw new RuntimeException('No synchronized cache miss observed.');
        }
        Cache::put($signals.':result:'.$reader, [
            'queries' => $queries,
            'sql_ms' => round($sqlMilliseconds, 3),
            'wait_ms' => round($waitMilliseconds, 3),
            'read_ms' => round((hrtime(true) - $start) / 1e6, 3),
            'digest' => self::digest($page),
        ], 30);
    }

    public static function pauseAfterRead(string $owner, GetAllExpenseInput $input, string $mode, string $signals): void
    {
        DB::listen(static function (QueryExecuted $event) use ($signals): void {
            if (str_contains($event->sql, 'from "expenses"')) {
                Cache::put($signals.':loaded', true, 30);
                self::await($signals.':release', true);
            }
        });
        $repository = app(ExpenseRepository::class);
        $read = static fn () => $repository->getAll($owner, $input);
        $page = $mode === 'original' ? $read() : Cache::lock('step8:page:'.hash('sha256', self::key($owner, $input)), 2)->block(1, $read);
        Cache::put($signals.':result', ['amount' => $page->items[0]->amount], 30);
    }

    public static function seed(string $owner, int $count): void
    {
        $rows = [];
        for ($index = 1; $index <= $count; $index++) {
            $rows[] = [
                'id' => UuidFixture::at($index),
                'user_id' => $owner,
                'amount' => 1000 + $index % 500,
                'category' => 'food',
                'description' => sprintf('Despesa %04d', $index % 900),
                'occurred_on' => sprintf('2026-09-%02d', 1 + $index % 28),
                'created_at' => '2026-10-16 12:00:00',
                'updated_at' => '2026-10-16 12:00:00',
            ];
            if (count($rows) === 1000 || $index === $count) {
                DB::table('expenses')->insert($rows);
                $rows = [];
            }
        }
        DB::statement('ANALYZE expenses');
        app(EloquentExpenseRepository::class)->getAll($owner, new GetAllExpenseInput);
    }
}
