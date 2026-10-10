<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Infrastructure\Adapters\Observability\ObservabilityAdapter;
use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use App\Identity\Domain\Enums\UserStatusEnum;
use Tests\Support\Core\Fixtures\ObservabilityLogFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    $this->observabilityLog = new ObservabilityLogFixture;
});

afterEach(function (): void {
    $this->observabilityLog->close();
});

it('keeps a confirmed creation successful when a controlled log destination fails', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $this->app->bind(ObservabilityPort::class, fn (): ObservabilityPort => new ObservabilityAdapter);
    $this->observabilityLog->failDestination();

    $response = $this->withToken($token)->postJson(route('expenses.create'), [
        'data' => ['type' => 'expenses', 'attributes' => [
            'amount' => 1500, 'category' => 'food', 'occurred_on' => '2026-09-24',
        ]],
    ])->assertCreated();

    $expense = ExpenseModel::query()->findOrFail($response->json('data.id'));
    expect($expense->amount)->toBe(1500)
        ->and($expense->user_id)->toBe($user->getKey())
        ->and($this->observabilityLog->records())->toBe([]);
});
