<?php

declare(strict_types=1);

use App\Expense\Application\UseCases\ClassifyExpenseUseCase;
use App\Expense\Infrastructure\Agents\ExpenseClassificationAgent;
use App\Expense\Infrastructure\Queues\ClassifyExpenseQueue;
use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;
use Tests\Support\Expense\Fixtures\ExpenseQueryHistoryFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    $this->owner = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->withToken(IdentityFixture::token($this->owner, expiresAt: now()->addDays(30)));
    config()->set('queue.default', 'redis');
    Queue::fake();
    ExpenseClassificationAgent::fake()->preventStrayPrompts();
});

it('persists and returns each explicit category without dispatching classification', function (string $category): void {
    $response = $this->postJson(route('expenses.create'), [
        'data' => ['type' => 'expenses', 'attributes' => [
            'amount' => 1500, 'occurred_on' => '2026-09-25', 'category' => $category, 'description' => 'Mercado - 2 itens',
        ]],
    ])->assertCreated()->assertJsonPath('data.attributes.category', $category);

    $this->assertDatabaseHas('expenses', [
        'id' => $response->json('data.id'), 'user_id' => $this->owner->id,
        'category' => $category, 'classification_token' => null,
    ]);
    $this->getJson(route('expenses.show', ['expense' => $response->json('data.id')]))
        ->assertOk()->assertJsonPath('data.attributes.category', $category);
    Queue::assertNothingPushed();
    ExpenseClassificationAgent::assertNeverPrompted();
})->with([
    'food', 'health', 'housing', 'leisure', 'shopping', 'services', 'transport', 'education', 'subscriptions', 'other',
    'financing', 'investments', 'taxes', 'insurance', 'personal_care', 'pets', 'gifts_and_donations', 'travel',
]);

it('returns and persists a manual edit and cancels its earlier classification attempt', function (string $category): void {
    $response = $this->postJson(route('expenses.create'), [
        'data' => ['type' => 'expenses', 'attributes' => [
            'amount' => 1500, 'occurred_on' => '2026-09-25', 'description' => 'Mercado - 2 itens',
        ]],
    ])->assertCreated()->assertJsonPath('data.attributes.category', 'other');
    $expense = ExpenseModel::query()->findOrFail($response->json('data.id'));
    $attemptToken = $expense->classification_token;
    expect($attemptToken)->toBeString();
    Queue::assertPushed(ClassifyExpenseQueue::class);

    $this->patchJson(route('expenses.update', ['expense' => $expense->id]), [
        'data' => ['type' => 'expenses', 'attributes' => ['category' => $category]],
    ])->assertOk()->assertJsonPath('data.attributes.category', $category);

    (new ClassifyExpenseQueue(token: $attemptToken, expenseId: $expense->id, tries: 3, timeout: 15))
        ->handle(useCase: app(ClassifyExpenseUseCase::class));

    $this->assertDatabaseHas('expenses', ['id' => $expense->id, 'category' => $category, 'classification_token' => null]);
    ExpenseClassificationAgent::assertNeverPrompted();
})->with(['financing', 'investments', 'taxes', 'insurance', 'personal_care', 'pets', 'gifts_and_donations', 'travel']);

it('filters each category before pagination and excludes another owner', function (string $category): void {
    $expected = ExpenseQueryHistoryFixture::create($this->owner->id, '2026-09-01', 1500, $category);
    ExpenseQueryHistoryFixture::create($this->owner->id, '2026-09-30', 1500, $category === 'other' ? 'health' : 'other');
    $other = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'other-category@example.com');
    ExpenseQueryHistoryFixture::create($other->id, '2026-09-30', 1500, $category);

    $this->getJson(route('expenses.index', ['filter' => ['category' => $category], 'page' => ['size' => 1]]))
        ->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', (string) $expected)
        ->assertJsonPath('data.0.attributes.category', $category)->assertJsonPath('links.next', null);
})->with([
    'food', 'health', 'housing', 'leisure', 'shopping', 'services', 'transport', 'education', 'subscriptions', 'other',
    'financing', 'investments', 'taxes', 'insurance', 'personal_care', 'pets', 'gifts_and_donations', 'travel',
]);

it('normalizes the mixed category set and combines owner date amount and cursor criteria', function (): void {
    $food = ExpenseQueryHistoryFixture::create($this->owner->id, '2026-09-01', 1000, 'food');
    $investment = ExpenseQueryHistoryFixture::create($this->owner->id, '2026-09-15', 2000, 'investments');
    $travel = ExpenseQueryHistoryFixture::create($this->owner->id, '2026-09-30', 30000, 'travel');
    foreach ([
        ['2026-10-01', 1500, 'travel'], ['2026-08-31', 1500, 'investments'],
        ['2026-09-30', 999, 'travel'], ['2026-09-30', 30001, 'investments'], ['2026-09-30', 1500, 'taxes'],
    ] as [$date, $amount, $category]) {
        ExpenseQueryHistoryFixture::create($this->owner->id, $date, $amount, $category);
    }
    $other = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'other-filter@example.com');
    ExpenseQueryHistoryFixture::create($other->id, '2026-09-30', 30000, 'travel');
    $parameters = [
        'filter' => ['category' => 'travel,investments,food,travel', 'from' => '2026-09-01', 'to' => '2026-09-30', 'amount_min' => 1000, 'amount_max' => 30000],
        'page' => ['size' => 2],
    ];
    $first = $this->getJson(route('expenses.index', $parameters))->assertOk()->assertJsonCount(2, 'data');
    expect(array_column($first->json('data'), 'id'))->toBe([(string) $travel, (string) $investment]);
    $next = $first->json('links.next');
    expect($next)->toBeString();
    $parameters['filter']['category'] = 'food,investments,travel';
    $normalized = $this->getJson(route('expenses.index', $parameters))->assertOk();
    expect($normalized->json('data'))->toBe($first->json('data'));
    $this->getJson($next)->assertOk()->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.id', (string) $food)->assertJsonPath('links.next', null);
});

it('rejects unknown and similar categories without creating editing or silently ignoring filter tokens', function (string $category): void {
    $this->postJson(route('expenses.create'), [
        'data' => ['type' => 'expenses', 'attributes' => ['amount' => 1500, 'category' => $category]],
    ])->assertUnprocessable()->assertJsonFragment(['pointer' => '/data/attributes/category']);
    $this->assertDatabaseCount('expenses', 0);
    $id = ExpenseQueryHistoryFixture::create($this->owner->id, '2026-09-25', 1500, 'other');
    $before = DB::table('expenses')->where('id', $id)->first();
    $this->patchJson(route('expenses.update', ['expense' => $id]), [
        'data' => ['type' => 'expenses', 'attributes' => ['category' => $category]],
    ])->assertUnprocessable()->assertJsonFragment(['pointer' => '/data/attributes/category']);
    $this->getJson(route('expenses.index', ['filter' => ['category' => 'travel,'.$category]]))
        ->assertUnprocessable()->assertJsonFragment(['pointer' => '/filter/category']);
    expect(DB::table('expenses')->where('id', $id)->first())->toEqual($before);
    Queue::assertNothingPushed();
    ExpenseClassificationAgent::assertNeverPrompted();
})->with(['unknown', 'investment', 'Travel', 'personal-care']);

it('keeps historical generic categories unchanged and readable despite more specific descriptions', function (): void {
    $transport = ExpenseQueryHistoryFixture::create($this->owner->id, '2025-09-01', 1500, 'transport', 'Passagem aérea para as férias');
    $other = ExpenseQueryHistoryFixture::create($this->owner->id, '2025-09-02', 2000, 'other', 'Aporte em renda fixa');
    $before = DB::table('expenses')->orderBy('id')->get()->all();

    $this->getJson(route('expenses.show', ['expense' => $transport]))->assertOk()->assertJsonPath('data.attributes.category', 'transport');
    $this->getJson(route('expenses.show', ['expense' => $other]))->assertOk()->assertJsonPath('data.attributes.category', 'other');
    $this->getJson(route('expenses.index'))->assertOk()->assertJsonCount(2, 'data');
    expect(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($before);
    Queue::assertNothingPushed();
    ExpenseClassificationAgent::assertNeverPrompted();
});
