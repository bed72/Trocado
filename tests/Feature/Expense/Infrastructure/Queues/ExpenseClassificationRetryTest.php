<?php

declare(strict_types=1);

use App\Core\Domain\Enums\ExpenseCategoryEnum;
use App\Expense\Application\Ports\ExpenseClassificationDispatchPort;
use App\Expense\Infrastructure\Queues\ClassifyExpenseQueue;
use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Queue\Events\JobExceptionOccurred;
use Illuminate\Queue\Events\JobReleasedAfterException;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Queue;
use Laravel\Ai\Exceptions\ProviderConnectionException;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('processes OpenRouter connection failures through the real Redis worker retry lifecycle', function (int $failures): void {
    $this->travelTo(now()->startOfSecond());
    config()->set('queue.default', 'redis');
    config()->set('queue.connections.redis.block_for', null);
    config()->set('queue.failed.driver', 'database-uuids');
    config()->set('queue.failed.database', 'pgsql');
    config()->set('queue.failed.table', 'failed_jobs');
    config()->set('expense.classification.provider', 'openrouter');
    config()->set('expense.classification.model', 'openai/gpt-4o-mini');
    config()->set('ai.providers.openrouter.key', 'test-only-key');
    config()->set('ai.providers.openrouter.url', 'https://openrouter.ai/api/v1');

    $sentinel = 'Simulated cURL error 28: Operation timed out after 15000 milliseconds';
    $responses = Http::sequence();
    for ($failure = 0; $failure < $failures; $failure++) {
        $responses->pushFailedConnection($sentinel);
    }
    $responses->push([
        'model' => 'openai/gpt-4o-mini',
        'choices' => [[
            'message' => ['role' => 'assistant', 'content' => '{"category":"food"}'],
            'finish_reason' => 'stop',
        ]],
    ]);
    Http::preventStrayRequests();
    Http::fake(['https://openrouter.ai/api/v1/chat/completions' => $responses]);

    $exceptions = [];
    $releases = [];
    Event::listen(JobExceptionOccurred::class, function (JobExceptionOccurred $event) use (&$exceptions): void {
        $exceptions[] = $event;
    });
    Event::listen(JobReleasedAfterException::class, function (JobReleasedAfterException $event) use (&$releases): void {
        $releases[] = $event;
    });

    $identity = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = 'classification-connection-test';
    $expiresAt = now()->addMinutes(10);
    $expense = ExpenseModel::query()->create([
        'user_id' => $identity->getKey(),
        'amount' => 1500,
        'occurred_on' => '2026-10-14',
        'description' => 'Mercado - 2 itens',
        'category' => ExpenseCategoryEnum::Other->value,
        'classification_token' => $token,
        'classification_expires_at' => $expiresAt,
    ]);
    app(ExpenseClassificationDispatchPort::class)->dispatch(token: $token, expenseId: $expense->id);

    $queue = config('expense.classification.queue');
    $connection = Queue::connection('redis');
    $payload = $connection->getConnection()->lindex('queues:'.$queue, 0);
    $queued = json_decode($payload, true, flags: JSON_THROW_ON_ERROR);
    $uuid = $queued['uuid'];
    expect($queued['displayName'])->toBe(ClassifyExpenseQueue::class)
        ->and($queued['maxTries'])->toBe(3)
        ->and($queued['timeout'])->toBe(25)
        ->and($connection->pendingSize($queue))->toBe(1);
    Http::assertNothingSent();

    $worker = static function () use ($queue): void {
        Artisan::call('queue:work', [
            'connection' => 'redis',
            '--queue' => $queue,
            '--once' => true,
            '--sleep' => 0,
        ]);
    };

    for ($attempt = 1; $attempt <= $failures; $attempt++) {
        $worker();

        expect($exceptions)->toHaveCount($attempt);
        $event = $exceptions[$attempt - 1];
        expect($event->exception)->toBeInstanceOf(ProviderConnectionException::class)
            ->and($event->exception->getMessage())->toBe('Could not connect to AI provider [openrouter].')
            ->and($event->exception->getPrevious())->toBeInstanceOf(ConnectionException::class)
            ->and($event->exception->getPrevious()->getMessage())->toBe($sentinel)
            ->and($event->job->uuid())->toBe($uuid)
            ->and($event->job->attempts())->toBe($attempt)
            ->and($expense->refresh()->category)->toBe(ExpenseCategoryEnum::Other->value);

        if ($attempt < 3) {
            $delay = $attempt === 1 ? 5 : 30;
            expect($releases)->toHaveCount($attempt)
                ->and($releases[$attempt - 1]->backoff)->toBe($delay)
                ->and($connection->delayedSize($queue))->toBe(1)
                ->and($connection->pendingSize($queue))->toBe(0)
                ->and($connection->reservedSize($queue))->toBe(0)
                ->and(DB::table('failed_jobs')->where('uuid', $uuid)->exists())->toBeFalse()
                ->and($expense->classification_token)->toBe($token)
                ->and($expense->classification_expires_at->equalTo($expiresAt))->toBeTrue();

            $this->travel($delay - 1)->seconds();
            $worker();
            expect($exceptions)->toHaveCount($attempt)
                ->and($connection->delayedSize($queue))->toBe(1);
            $this->travel(1)->seconds();
        }
    }

    if ($failures < 3) {
        $worker();
        expect($expense->refresh()->category)->toBe(ExpenseCategoryEnum::Food->value)
            ->and($exceptions)->toHaveCount($failures)
            ->and(DB::table('failed_jobs')->where('uuid', $uuid)->exists())->toBeFalse();
        Http::assertSentCount($failures + 1);
    } else {
        $failed = DB::table('failed_jobs')->where('uuid', $uuid)->sole();
        expect($failed->connection)->toBe('redis')
            ->and($failed->queue)->toBe($queue)
            ->and($failed->exception)->toContain(ProviderConnectionException::class, $sentinel)
            ->and($releases)->toHaveCount(2);
        $worker();
        expect($exceptions)->toHaveCount(3)
            ->and($expense->refresh()->category)->toBe(ExpenseCategoryEnum::Other->value);
        Http::assertSentCount(3);
    }

    expect($expense->classification_token)->toBeNull()
        ->and($expense->classification_expires_at)->toBeNull()
        ->and($expense->amount)->toBe(1500)
        ->and($expense->description)->toBe('Mercado - 2 itens')
        ->and($connection->size($queue))->toBe(0);
})->with([
    'connection recovers on the second attempt' => [1],
    'connection recovers on the final allowed attempt' => [2],
    'connection fails on all three attempts' => [3],
])->group('integration', 'worker', 'redis');
