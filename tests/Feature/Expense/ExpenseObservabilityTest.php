<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Infrastructure\Adapters\Observability\ObservabilityAdapter;
use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

use function Pest\Laravel\withToken;

beforeEach(function (): void {
    $this->observabilityPath = storage_path('logs/observability-test-'.uniqid().'.log');
    config()->set('logging.channels.observability.handler_with.stream', $this->observabilityPath);
    Log::forgetChannel('observability');
});

afterEach(function (): void {
    Log::forgetChannel('observability');
    @unlink($this->observabilityPath);
});

it('writes one correlated structured event only for a confirmed expense', function (): void {
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

    expect($records)->toHaveCount(2)
        ->and($records[0]['event'])->toBe('expense.created')
        ->and($records[0]['expense_id'])->toBe((int) $first->json('data.id'))
        ->and($records[0]['user_id'])->toBe($userId)
        ->and($records[0]['request_id'])->toBe($first->headers->get('X-Request-Id'))
        ->and($records[0]['timestamp'])->toBeString()
        ->and($records[0]['level'])->toBe('INFO')
        ->and($records[1]['request_id'])->toBe($second->headers->get('X-Request-Id'))
        ->and($second->headers->get('X-Request-Id'))->not->toBe($first->headers->get('X-Request-Id'))
        ->and(json_encode($records))->not->toContain('private description', '1500', $token);

    app(ObservabilityPort::class)->emit('outside.http', ['expense_id' => 42]);
    $lines = file($this->observabilityPath, FILE_IGNORE_NEW_LINES);
    $outside = json_decode($lines[2], true, flags: JSON_THROW_ON_ERROR);

    expect($outside)->not->toHaveKey('request_id');
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

    expect(ExpenseModel::query()->count())->toBe(0)
        ->and($rejected->headers->get('X-Request-Id'))->toBeString()
        ->and(file_exists($this->observabilityPath))->toBeFalse();
});

it('keeps a confirmed creation successful when the log destination fails', function (): void {
    signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $this->app->bind(ObservabilityPort::class, fn (): ObservabilityPort => new ObservabilityAdapter);
    config()->set('logging.channels.observability.handler_with.stream', '/nonexistent/observability/output.log');
    Log::forgetChannel('observability');

    withToken($token)->postJson(route('expenses.create'), [
        'data' => ['type' => 'expenses', 'attributes' => [
            'amount' => 1500, 'category' => 'food', 'occurred_on' => '2026-09-24',
        ]],
    ])->assertCreated();

    expect(ExpenseModel::query()->count())->toBe(1);
});
