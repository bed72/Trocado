<?php

declare(strict_types=1);

use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
use Tests\Support\Core\Fixtures\ObservabilityLogFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;
use Tests\Support\Identity\Helpers\IdentityHttpJourney;

use function Pest\Laravel\withToken;

beforeEach(function (): void {
    $this->observabilityLog = new ObservabilityLogFixture;
});

afterEach(function (): void {
    $this->observabilityLog->close();
});

it('wires confirmed identity and expense mutations to correlated business events', function (): void {
    Notification::fake();
    $journey = new IdentityHttpJourney($this);
    $userId = $journey->signUp();
    $user = UserModel::query()->findOrFail($userId);
    $journey->verifyEmail($user, expiresAt: now()->addHour());
    $user->update(['status' => UserStatusEnum::Active]);
    $token = $journey->signIn();

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
    $records = $this->observabilityLog->records();
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
        ->and(json_encode($records))->not->toContain('private description', $token);

    foreach ($records as $record) {
        expect($record)->not->toHaveKeys(['amount', 'description', 'password', 'token', 'payload']);
    }

    $updated = withToken($token)->patchJson(route('expenses.update', ['expense' => $first->json('data.id')]), [
        'data' => ['type' => 'expenses', 'attributes' => ['amount' => 2500]],
    ])->assertOk();
    $deleted = withToken($token)->deleteJson(route('expenses.delete', ['expense' => $second->json('data.id')]))->assertNoContent();
    $userUpdated = withToken($token)->patchJson(route('users.update', ['user' => $userId]), [
        'data' => ['type' => 'users', 'id' => (string) $userId, 'attributes' => ['name' => 'Maria Silva']],
    ])->assertOk();
    $signedOut = withToken($token)->deleteJson(route('authentication.api.sign-out'))->assertNoContent();
    $newToken = $journey->signIn();
    $userDeleted = withToken($newToken)->deleteJson(route('users.delete', ['user' => $userId]))->assertNoContent();

    $mutationRecords = $this->observabilityLog->records();

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
    IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = (new IdentityHttpJourney($this))->signIn();

    $sentinel = new RuntimeException('Abort confirmed request before outer commit.');

    try {
        DB::transaction(function () use ($token, $sentinel): void {
            withToken($token)->postJson(route('expenses.create'), [
                'data' => ['type' => 'expenses', 'attributes' => [
                    'amount' => 1500, 'category' => 'food', 'occurred_on' => '2026-09-24',
                ]],
            ])->assertCreated();

            expect(ExpenseModel::query()->count())->toBe(1);

            throw $sentinel;
        });
        $this->fail('The transaction must propagate the sentinel.');
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($sentinel);
    }

    $rejected = withToken($token)->postJson(route('expenses.create'), [
        'data' => ['type' => 'expenses', 'attributes' => ['amount' => -1]],
    ])->assertUnprocessable();

    $records = $this->observabilityLog->records();

    expect(ExpenseModel::query()->count())->toBe(0)
        ->and($rejected->headers->get('X-Request-Id'))->toBeString()
        ->and(array_filter($records, fn (array $record): bool => $record['event'] === 'expense.created'))->toBeEmpty()
        ->and(DB::transactionLevel())->toBe(0);
});
