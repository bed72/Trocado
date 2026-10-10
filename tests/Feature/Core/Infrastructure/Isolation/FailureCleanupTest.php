<?php

declare(strict_types=1);

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Redis;
use Tests\Support\Core\Database\TestDatabaseCleanup;
use Tests\Support\Core\Fixtures\ConcurrentDatabaseProcess;
use Tests\Support\Core\Fixtures\ObservabilityWorkerProbe;

it('cleans jobs failed jobs Redis logs transactions and a child after a controlled scenario failure', function (): void {
    $queue = config('queue.connections.redis.queue');
    Redis::set('failure-sentinel', 'owned');
    Queue::connection('redis')->push((new ObservabilityWorkerProbe)->onQueue($queue), queue: $queue);
    Queue::connection('database')->push(new ObservabilityWorkerProbe, queue: $queue);
    DB::table('failed_jobs')->insert(['uuid' => 'isolation-failure', 'connection' => 'database', 'queue' => $queue, 'payload' => '{}', 'exception' => 'sentinel', 'failed_at' => now()]);
    expect(DB::table('jobs')->count())->toBe(1)
        ->and(DB::table('failed_jobs')->count())->toBe(1)
        ->and(Queue::connection('redis')->size($queue))->toBe(1);
    $child = new ConcurrentDatabaseProcess(static function (): void {
        throw new RuntimeException('child-failure-sentinel');
    });
    $failure = new RuntimeException('scenario-failure-sentinel');
    try {
        $child->go();
        expect(fn () => $child->done())->toThrow(RuntimeException::class, 'child-failure-sentinel');
        DB::beginTransaction();
        throw $failure;
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($failure);
    } finally {
        $child->close();
        $this->resources->close();
        TestDatabaseCleanup::clean($this->app);
    }
    expect(pcntl_waitpid($child->pid, $status, WNOHANG))->toBe(-1)
        ->and(DB::transactionLevel())->toBe(0)
        ->and(DB::table('jobs')->count())->toBe(0)
        ->and(DB::table('failed_jobs')->count())->toBe(0)
        ->and(Redis::get('failure-sentinel'))->toBeNull()
        ->and(Queue::connection('redis')->size($queue))->toBe(0)
        ->and(is_file($this->resources->log))->toBeFalse()
        ->and(DB::table('migrations')->count())->toBeGreaterThan(0);
})->group('integration', 'redis', 'concurrency');

it('bounds termination of a child that does not finish its operation', function (): void {
    $child = new ConcurrentDatabaseProcess(static function (): void {
        while (true) {
            usleep(10000);
        }
    });
    try {
        $child->go();
    } finally {
        $child->close();
    }
    expect(pcntl_waitpid($child->pid, $status, WNOHANG))->toBe(-1)
        ->and(DB::transactionLevel())->toBe(0);
})->group('integration', 'concurrency');
