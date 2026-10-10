<?php

declare(strict_types=1);

use App\Core\Infrastructure\Adapters\TransactionAdapter;
use Illuminate\Database\DeadlockException;
use Illuminate\Support\Facades\DB;

it('commits a real write returns its result and releases callbacks in registration order', function (): void {
    $adapter = new TransactionAdapter;
    $events = [];

    $id = $adapter->commit(function () use ($adapter, &$events): int {
        expect(DB::transactionLevel())->toBe(1);
        $id = DB::table('users')->insertGetId(['name' => 'Maria', 'email' => 'commit@example.com', 'password' => 'unused']);
        $adapter->afterCommit(function () use ($id, &$events): void {
            expect(DB::transactionLevel())->toBe(0)
                ->and(DB::table('users')->where('id', $id)->exists())->toBeTrue();
            $events[] = 'first';
        });
        $adapter->afterCommit(function () use (&$events): void {
            $events[] = 'second';
        });
        expect($events)->toBe([]);

        return $id;
    });

    expect($id)->toBeInt()
        ->and(DB::table('users')->where('id', $id)->exists())->toBeTrue()
        ->and($events)->toBe(['first', 'second'])
        ->and(DB::transactionLevel())->toBe(0);
});

it('rolls back a demonstrated write preserves the sentinel and discards callbacks', function (): void {
    $adapter = new TransactionAdapter;
    $sentinel = new RuntimeException('Abort after writing.');
    $called = false;
    $written = false;

    try {
        $adapter->commit(function () use ($adapter, $sentinel, &$called, &$written): void {
            DB::table('users')->insert(['name' => 'Maria', 'email' => 'rollback@example.com', 'password' => 'unused']);
            $written = DB::table('users')->where('email', 'rollback@example.com')->exists();
            expect($written)->toBeTrue();
            $adapter->afterCommit(function () use (&$called): void {
                $called = true;
            });

            throw $sentinel;
        });
        $this->fail('The transaction must propagate the sentinel.');
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($sentinel);
    }

    expect($written)->toBeTrue()
        ->and(DB::table('users')->where('email', 'rollback@example.com')->exists())->toBeFalse()
        ->and($called)->toBeFalse()
        ->and(DB::transactionLevel())->toBe(0);
});

it('executes an outside callback immediately and defers a nested one to the outer commit', function (): void {
    $adapter = new TransactionAdapter;
    $events = [];
    $adapter->afterCommit(function () use (&$events): void {
        $events[] = 'outside';
    });
    expect($events)->toBe(['outside']);

    DB::transaction(function () use ($adapter, &$events): void {
        expect($adapter->commit(function () use ($adapter, &$events): string {
            $adapter->afterCommit(function () use (&$events): void {
                $events[] = 'nested';
            });

            return 'result';
        }))->toBe('result');
        expect($events)->toBe(['outside']);
    });

    expect($events)->toBe(['outside', 'nested'])
        ->and(DB::transactionLevel())->toBe(0);
});

it('retries an injected concurrency failure after writing and releases only the successful callback', function (): void {
    $adapter = new TransactionAdapter;
    $attempts = 0;
    $callbacks = [];
    $abortedId = null;

    $id = $adapter->commit(function () use ($adapter, &$attempts, &$callbacks, &$abortedId): int {
        $attempt = ++$attempts;
        $id = DB::table('users')->insertGetId(['name' => 'Maria', 'email' => 'retry@example.com', 'password' => 'unused']);
        expect(DB::table('users')->where('id', $id)->exists())->toBeTrue();
        $adapter->afterCommit(function () use ($attempt, &$callbacks): void {
            $callbacks[] = $attempt;
        });
        expect($callbacks)->toBe([]);

        if ($attempt === 1) {
            $abortedId = $id;

            throw new DeadlockException('deadlock detected after callback registration');
        }

        return $id;
    });

    expect($attempts)->toBe(2)
        ->and($callbacks)->toBe([2])
        ->and(DB::table('users')->where('email', 'retry@example.com')->count())->toBe(1)
        ->and(DB::table('users')->where('id', $abortedId)->exists())->toBeFalse()
        ->and(DB::table('users')->where('id', $id)->exists())->toBeTrue()
        ->and(DB::transactionLevel())->toBe(0);
});
