<?php

declare(strict_types=1);

namespace Tests\Support\Core\Fixtures;

use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Cache\RateLimiter;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Redis;
use RuntimeException;
use Tests\FeatureTestCase;
use Tests\Support\Core\Database\TestDatabaseRun;
use Tests\Support\Identity\Fixtures\IdentityFixture;

final class ExecutionIsolationProbe
{
    public static function exercise(FeatureTestCase $test): void
    {
        $run = TestDatabaseRun::fromEnvironment();
        $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'same-isolation@example.com');
        $user->forceFill(['id' => 1500])->save();
        $queue = config('queue.connections.redis.queue');
        Redis::set('sentinel:1500', $run->database);
        $cache = Cache::store('redis');
        $cache->put('page:1500', $run->database, 60);
        $limiter = new RateLimiter($cache);
        $limiter->hit('quota:1500', 60);
        Queue::connection('redis')->push((new ObservabilityWorkerProbe)->onQueue($queue), queue: $queue);
        file_put_contents($test->resources->log, $run->database);
        $report = [
            'run' => $run->id, 'token' => $run->token, 'database' => DB::selectOne('select current_database() as name')->name,
            'namespace' => $test->resources->namespace, 'queue' => $queue, 'log' => $test->resources->log,
        ];
        $directory = getenv('TROCADO_TEST_PROBE_DIR');
        if ($directory !== false) {
            file_put_contents($directory.'/'.$run->id.'-'.$run->token.'.json', json_encode($report, JSON_THROW_ON_ERROR));
            $deadline = microtime(true) + 30;
            while (! is_file($directory.'/'.$run->id.'.release')) {
                if (microtime(true) > $deadline) {
                    throw new RuntimeException('Invocation isolation barrier timed out.');
                }
                usleep(10000);
            }
        }
        expect($report['database'])->toBe($run->database)
            ->and(DB::table('users')->where('id', 1500)->value('email'))->toBe('same-isolation@example.com')
            ->and(DB::table('users')->count())->toBe(1)
            ->and(Redis::get('sentinel:1500'))->toBe($run->database)
            ->and($cache->get('page:1500'))->toBe($run->database)
            ->and((int) $limiter->attempts('quota:1500'))->toBe(1)
            ->and(Queue::connection('redis')->size($queue))->toBe(1)
            ->and(file_get_contents($test->resources->log))->toBe($run->database);
    }
}
