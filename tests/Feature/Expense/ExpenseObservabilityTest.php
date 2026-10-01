<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Infrastructure\Adapters\Observability\ObservabilityAdapter;
use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use Illuminate\Contracts\Queue\Job;
use Illuminate\Queue\Events\JobFailed;
use Illuminate\Queue\Events\JobProcessed;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Log;

use function Pest\Laravel\withToken;

beforeEach(function (): void {
    $this->observabilityPath = storage_path('logs/observability-test-'.uniqid().'.log');
    config()->set('logging.channels.observability_stderr.handler_with.stream', $this->observabilityPath);
    Log::forgetChannel('observability');
    Log::forgetChannel('observability_stderr');
});

afterEach(function (): void {
    Log::forgetChannel('observability');
    Log::forgetChannel('observability_stderr');
    @unlink($this->observabilityPath);
});

it('writes correlated events for confirmed mutations and queue outcomes', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $first = withToken($token)->postJson(route('expenses.create'), [
        'data' => ['type' => 'expenses', 'attributes' => [
            'amount' => 1500,
            'category' => 'food',
            'description' => 'private description',
            'occurred_on' => '2026-09-24',
        ]],
    ])->assertCreated();

    $second = withToken($token)->postJson(route('expenses.create'), [
        'data' => ['type' => 'expenses', 'attributes' => [
            'amount' => 2000, 'category' => 'food', 'occurred_on' => '2026-09-24',
        ]],
    ])->assertCreated();
    $records = array_map(fn (string $line): array => json_decode($line, true, flags: JSON_THROW_ON_ERROR), file($this->observabilityPath, FILE_IGNORE_NEW_LINES));
    $expenseRecords = array_values(array_filter($records, fn (array $record): bool => $record['event'] === 'expense.created'));

    expect($expenseRecords)->toHaveCount(2)
        ->and(array_column($records, 'event'))->toContain('user.registered', 'identity.signed_in')
        ->and($expenseRecords[0]['expense_id'])->toBe((int) $first->json('data.id'))
        ->and($expenseRecords[0]['user_id'])->toBe($userId)
        ->and($expenseRecords[0]['request_id'])->toBe($first->headers->get('X-Request-Id'))
        ->and($expenseRecords[0]['timestamp'])->toBeString()
        ->and($expenseRecords[0]['level'])->toBe('INFO')
        ->and($expenseRecords[1]['request_id'])->toBe($second->headers->get('X-Request-Id'))
        ->and($second->headers->get('X-Request-Id'))->not->toBe($first->headers->get('X-Request-Id'))
        ->and(json_encode($records))->not->toContain('private description', '1500', $token);

    app(ObservabilityPort::class)->emit('outside.http', ['expense_id' => 42]);
    $lines = file($this->observabilityPath, FILE_IGNORE_NEW_LINES);
    $outside = json_decode($lines[count($records)], true, flags: JSON_THROW_ON_ERROR);

    expect($outside)->not->toHaveKey('request_id');

    $job = $this->createMock(Job::class);
    $job->method('getQueue')->willReturn('expense-classification');
    $job->method('getJobId')->willReturn('job-1');
    $job->method('resolveName')->willReturn('ClassifyExpenseQueue');
    $job->method('attempts')->willReturn(3);
    Event::dispatch(new JobProcessed('redis', $job));
    Event::dispatch(new JobFailed('redis', $job, new RuntimeException('sensitive job payload')));

    $queueRecords = array_map(fn (string $line): array => json_decode($line, true, flags: JSON_THROW_ON_ERROR), array_slice(file($this->observabilityPath, FILE_IGNORE_NEW_LINES), -2));

    expect($queueRecords[0])->toMatchArray(['event' => 'queue.job_processed', 'queue' => 'expense-classification', 'job_id' => 'job-1', 'attempts' => 3])
        ->and($queueRecords[1])->toMatchArray(['event' => 'queue.job_failed', 'error_class' => RuntimeException::class])
        ->and($queueRecords[0])->not->toHaveKey('request_id')
        ->and(json_encode($queueRecords))->not->toContain('sensitive job payload');

    $updated = withToken($token)->patchJson(route('expenses.update', ['expense' => $first->json('data.id')]), [
        'data' => ['type' => 'expenses', 'attributes' => ['amount' => 2500]],
    ])->assertOk();
    $deleted = withToken($token)->deleteJson(route('expenses.delete', ['expense' => $second->json('data.id')]))->assertNoContent();
    $userUpdated = withToken($token)->patchJson(route('users.update', ['user' => $userId]), [
        'data' => ['type' => 'users', 'id' => (string) $userId, 'attributes' => ['name' => 'Maria Silva']],
    ])->assertOk();
    $signedOut = withToken($token)->deleteJson(route('authentication.api.sign-out'))->assertNoContent();
    $newToken = signInIdentityByApi($this);
    $userDeleted = withToken($newToken)->deleteJson(route('users.delete', ['user' => $userId]))->assertNoContent();

    $mutationRecords = array_map(fn (string $line): array => json_decode($line, true, flags: JSON_THROW_ON_ERROR), file($this->observabilityPath, FILE_IGNORE_NEW_LINES));

    foreach ([
        'expense.updated' => $updated,
        'expense.deleted' => $deleted,
        'user.updated' => $userUpdated,
        'identity.signed_out' => $signedOut,
        'user.deleted' => $userDeleted,
    ] as $event => $response) {
        $matching = array_values(array_filter($mutationRecords, fn (array $record): bool => $record['event'] === $event));

        expect($matching)->toHaveCount(1)
            ->and($matching[0]['request_id'])->toBe($response->headers->get('X-Request-Id'));
    }
});

it('does not emit on rollback or invalid input', function (): void {
    signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    try {
        DB::transaction(function () use ($token): void {
            withToken($token)->postJson(route('expenses.create'), [
                'data' => ['type' => 'expenses', 'attributes' => [
                    'amount' => 1500, 'category' => 'food', 'occurred_on' => '2026-09-24',
                ]],
            ])->assertCreated();

            throw new RuntimeException('rollback');
        });
    } catch (RuntimeException) {
    }

    $rejected = withToken($token)->postJson(route('expenses.create'), [
        'data' => ['type' => 'expenses', 'attributes' => ['amount' => -1]],
    ])->assertUnprocessable();

    $records = array_map(fn (string $line): array => json_decode($line, true, flags: JSON_THROW_ON_ERROR), file($this->observabilityPath, FILE_IGNORE_NEW_LINES));

    expect(ExpenseModel::query()->count())->toBe(0)
        ->and($rejected->headers->get('X-Request-Id'))->toBeString()
        ->and(array_filter($records, fn (array $record): bool => $record['event'] === 'expense.created'))->toBeEmpty();
});

it('keeps a confirmed creation successful when the log destination fails', function (): void {
    signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $this->app->bind(ObservabilityPort::class, fn (): ObservabilityPort => new ObservabilityAdapter);
    config()->set('logging.channels.observability_stderr.handler_with.stream', '/nonexistent/observability/output.log');
    Log::forgetChannel('observability');
    Log::forgetChannel('observability_stderr');

    withToken($token)->postJson(route('expenses.create'), [
        'data' => ['type' => 'expenses', 'attributes' => [
            'amount' => 1500, 'category' => 'food', 'occurred_on' => '2026-09-24',
        ]],
    ])->assertCreated();

    expect(ExpenseModel::query()->count())->toBe(1);
});
