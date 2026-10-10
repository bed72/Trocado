<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Contracts\Queue\Job;
use Illuminate\Queue\Events\JobFailed;
use Illuminate\Queue\Events\JobProcessed;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Context;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Route;
use Tests\Support\Core\Fixtures\ObservabilityLogFixture;
use Tests\Support\Core\Fixtures\ObservabilityWorkerProbe;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    $this->observabilityLog = new ObservabilityLogFixture;
});

afterEach(function (): void {
    $this->observabilityLog->close();
});

it('logs permitted worker metadata and error class without HTTP context or sensitive error message', function (): void {
    $job = $this->createStub(Job::class);
    $job->method('getQueue')->willReturn('expense-classification');
    $job->method('getJobId')->willReturn('job-1500');
    $job->method('resolveName')->willReturn('ClassifyExpenseQueue');
    $job->method('attempts')->willReturn(3);
    Event::dispatch(new JobProcessed('redis', $job));
    Event::dispatch(new JobFailed('redis', $job, new RuntimeException('sensitive job payload')));

    $records = $this->observabilityLog->records();
    expect($records)->toHaveCount(2);

    foreach ($records as $record) {
        expect($record)->toMatchArray([
            'level' => 'INFO', 'connection' => 'redis', 'queue' => 'expense-classification',
            'job_id' => 'job-1500', 'job' => 'ClassifyExpenseQueue', 'attempts' => 3,
        ])->not->toHaveKeys(['request_id', 'user_id', 'amount', 'description', 'password', 'token', 'payload', 'message'])
            ->and($record['timestamp'])->toBeString()
            ->and(array_values($record))->not->toContain('sensitive job payload');
    }

    expect($records[0]['event'])->toBe('queue.job_processed')
        ->and($records[0])->toHaveKey('duration_ms')
        ->and($records[1])->toMatchArray(['event' => 'queue.job_failed', 'error_class' => RuntimeException::class]);
});

it('does not report a released or failed job as successfully processed', function (string $state): void {
    $job = $this->createStub(Job::class);
    $job->method('hasFailed')->willReturn($state === 'failed');
    $job->method('isReleased')->willReturn($state === 'released');

    Event::dispatch(new JobProcessed('redis', $job));

    expect($this->observabilityLog->records())->toBe([]);
})->with(['failed', 'released']);

it('does not hydrate HTTP request fields into events emitted by a real serialized worker job', function (): void {
    $queue = 'observability-worker-test-'.bin2hex(random_bytes(12));
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    Route::post('/api/queue-observability-probe', function () use ($queue) {
        Context::add('probe_batch', 'batch-1500');
        Queue::connection('database')->push((new ObservabilityWorkerProbe)->onQueue($queue), queue: $queue);
        app(ObservabilityPort::class)->emit('probe.http', []);

        return response()->noContent();
    })->middleware(['auth:sanctum', 'request.authenticated']);

    try {
        $response = $this->withToken($token)->postJson('/api/queue-observability-probe')->assertNoContent();
        $payload = json_decode(DB::table('jobs')->where('queue', $queue)->sole()->payload, true, flags: JSON_THROW_ON_ERROR);
        expect($payload['displayName'])->toBe(ObservabilityWorkerProbe::class)
            ->and($response->headers->get('X-Request-Id'))->toBeString();

        Artisan::call('queue:work', ['connection' => 'database', '--queue' => $queue, '--once' => true, '--tries' => 1]);

        expect(DB::table('jobs')->where('queue', $queue)->count())->toBe(0)
            ->and(DB::table('failed_jobs')->where('queue', $queue)->count())->toBe(0);
        $records = $this->observabilityLog->records();
        expect(array_column($records, 'event'))->toBe(['probe.http', 'probe.worker', 'queue.job_processed'])
            ->and($records[0])->toMatchArray([
                'request_id' => $response->headers->get('X-Request-Id'),
                'trace_id' => $response->headers->get('X-Request-Id'),
                'http_method' => 'POST', 'path' => '/api/queue-observability-probe',
                'route' => 'api/queue-observability-probe', 'ip' => '127.0.0.1', 'user_id' => $user->getKey(),
            ])
            ->and($records[1]['expense_id'])->toBe(1500)
            ->and($records[2]['queue'])->toBe($queue);

        foreach (array_slice($records, 1) as $record) {
            expect($record)->not->toHaveKeys(['request_id', 'trace_id', 'http_method', 'path', 'ip', 'route', 'user_id'])
                ->and($record['probe_batch'])->toBe('batch-1500');
        }
    } finally {
        DB::table('jobs')->where('queue', $queue)->delete();
        DB::table('failed_jobs')->where('queue', $queue)->delete();
    }
});
