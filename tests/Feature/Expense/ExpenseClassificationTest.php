<?php

declare(strict_types=1);

use App\Expense\Application\Data\ApplyExpenseClassificationInput;
use App\Expense\Application\Ports\ExpenseClassificationDispatchPort;
use App\Expense\Application\Repositories\ExpenseCategorizationRepository;
use App\Expense\Application\UseCases\ClassifyExpenseUseCase;
use App\Expense\Domain\Enums\ExpenseCategoryEnum;
use App\Expense\Infrastructure\Agents\ExpenseClassificationAgent;
use App\Expense\Infrastructure\Providers\ExpenseServiceProvider;
use App\Expense\Infrastructure\Queues\ClassifyExpenseQueue;
use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;

use function Pest\Laravel\withToken;

beforeEach(function (): void {
    config()->set('queue.default', 'redis');
    Queue::fake();
    ExpenseClassificationAgent::fake();
});

function createClassifiableExpense(int $userId, string $token, ?string $category = null, ?string $description = 'Mercado - 2 itens'): ExpenseModel
{
    $attributes = [
        'amount' => 1500,
        'occurred_on' => '2026-09-25',
    ];

    if ($category !== null) {
        $attributes['category'] = $category;
    }

    if ($description !== null) {
        $attributes['description'] = $description;
    }

    withToken($token)->postJson(route('expenses.create'), [
        'data' => [
            'type' => 'expenses',
            'attributes' => $attributes,
        ],
    ])->assertCreated()->assertJsonPath('data.attributes.category', $category ?? 'other');

    return ExpenseModel::query()->where('user_id', $userId)->sole();
}

it('creates an eligible expense as other and queues classification without prompting AI in HTTP', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $expense = createClassifiableExpense(userId: $userId, token: $token);

    expect($expense->category)->toBe(ExpenseCategoryEnum::Other->value)
        ->and($expense->classification_token)->toBeString()->toHaveLength(32);
    Queue::assertPushedOn(queue: 'expense-classification', job: ClassifyExpenseQueue::class);
    Queue::assertPushed(ClassifyExpenseQueue::class, fn (ClassifyExpenseQueue $job): bool => $job->expenseId === $expense->id
        && $job->token === $expense->classification_token);
    ExpenseClassificationAgent::assertNeverPrompted();
});

it('configures the selected AI provider with the generic expense credential', function (): void {
    config()->set('expense.classification.provider', 'anthropic');
    config()->set('expense.classification.api_key', 'expense-example-key');
    config()->set('ai.providers.openai.key', 'unrelated-key');
    config()->set('ai.providers.anthropic.key', null);

    (new ExpenseServiceProvider(app: $this->app))->boot();

    expect(config('ai.providers.anthropic.key'))->toBe('expense-example-key')
        ->and(config('ai.providers.openai.key'))->toBe('unrelated-key');
});

it('keeps an existing provider credential when the generic expense credential is blank', function (): void {
    config()->set('expense.classification.provider', 'anthropic');
    config()->set('expense.classification.api_key', '');
    config()->set('ai.providers.anthropic.key', 'provider-example-key');

    (new ExpenseServiceProvider(app: $this->app))->boot();

    expect(config('ai.providers.anthropic.key'))->toBe('provider-example-key');
});

it('does not queue explicit categories, whitespace, or isolated injection payloads', function (?string $category, ?string $description): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $expense = createClassifiableExpense(userId: $userId, token: $token, category: $category, description: $description);

    expect($expense->classification_token)->toBeNull();
    Queue::assertNothingPushed();
    ExpenseClassificationAgent::assertNeverPrompted();
})->with([
    'explicit category' => ['transport', 'Uber 123'],
    'explicit other' => ['other', 'Mercado - 2 itens'],
    'whitespace only' => [null, '   '],
    'sql payload' => [null, "' OR '1'='1"],
    'xss payload' => [null, "<script>alert('hack')</script>"],
]);

it('rejects invalid HTTP input without creating or queuing an expense', function (): void {
    signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    withToken($token)->postJson(route('expenses.create'), [
        'data' => [
            'type' => 'expenses',
            'attributes' => [
                'amount' => 1500,
                'category' => 'unknown',
                'description' => 'Mercado - 2 itens',
            ],
        ],
    ])->assertUnprocessable();

    expect(ExpenseModel::query()->exists())->toBeFalse();
    Queue::assertNothingPushed();
    ExpenseClassificationAgent::assertNeverPrompted();
});

it('does not dispatch a classification when an enclosing transaction rolls back', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    try {
        DB::transaction(function () use ($token): void {
            withToken($token)->postJson(route('expenses.create'), [
                'data' => [
                    'type' => 'expenses',
                    'attributes' => [
                        'amount' => 1500,
                        'description' => 'Mercado - 2 itens',
                    ],
                ],
            ])->assertCreated();

            throw new RuntimeException('Rollback.');
        });
    } catch (RuntimeException) {
    }

    expect(ExpenseModel::query()->where('user_id', $userId)->exists())->toBeFalse();
    Queue::assertNothingPushed();
});

it('updates the category after the queued job receives a valid suggestion', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $expense = createClassifiableExpense(userId: $userId, token: $token);
    ExpenseClassificationAgent::fake([['category' => 'food']]);

    (new ClassifyExpenseQueue(token: $expense->classification_token, expenseId: $expense->id, tries: 3, timeout: 15))
        ->handle(useCase: app(ClassifyExpenseUseCase::class));
    (new ClassifyExpenseQueue(token: $expense->classification_token, expenseId: $expense->id, tries: 3, timeout: 15))
        ->handle(useCase: app(ClassifyExpenseUseCase::class));

    $expense->refresh();

    expect($expense->category)->toBe(ExpenseCategoryEnum::Food->value)
        ->and($expense->classification_token)->toBeNull();
    ExpenseClassificationAgent::assertPromptedTimes();
});

it('does not overwrite a category explicitly edited while the job was pending', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $expense = createClassifiableExpense(userId: $userId, token: $token);
    ExpenseClassificationAgent::fake([['category' => 'food']]);

    withToken($token)->patchJson(route('expenses.update', $expense), [
        'data' => [
            'type' => 'expenses',
            'attributes' => ['category' => 'other'],
        ],
    ])->assertOk();

    (new ClassifyExpenseQueue(token: $expense->classification_token, expenseId: $expense->id, tries: 3, timeout: 15))
        ->handle(useCase: app(ClassifyExpenseUseCase::class));

    $expense->refresh();

    expect($expense->category)->toBe(ExpenseCategoryEnum::Other->value)
        ->and($expense->classification_token)->toBeNull();
    ExpenseClassificationAgent::assertNeverPrompted();
});

it('does not overwrite an expense whose description was changed while the job was pending', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $expense = createClassifiableExpense(userId: $userId, token: $token);
    $classificationToken = $expense->classification_token;
    ExpenseClassificationAgent::fake([['category' => 'food']]);

    withToken($token)->patchJson(route('expenses.update', $expense), [
        'data' => [
            'type' => 'expenses',
            'attributes' => ['description' => 'Farmacia 123'],
        ],
    ])->assertOk();

    (new ClassifyExpenseQueue(token: $classificationToken, expenseId: $expense->id, tries: 3, timeout: 15))
        ->handle(useCase: app(ClassifyExpenseUseCase::class));

    $expense->refresh();

    expect($expense->category)->toBe(ExpenseCategoryEnum::Other->value)
        ->and($expense->description)->toBe('Farmacia 123')
        ->and($expense->classification_token)->toBeNull();
    ExpenseClassificationAgent::assertNeverPrompted();
});

it('does not classify an expense deleted while the job was pending', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $expense = createClassifiableExpense(userId: $userId, token: $token);
    $classificationToken = $expense->classification_token;
    ExpenseClassificationAgent::fake([['category' => 'food']]);

    withToken($token)->deleteJson(route('expenses.delete', $expense))->assertNoContent();

    (new ClassifyExpenseQueue(token: $classificationToken, expenseId: $expense->id, tries: 3, timeout: 15))
        ->handle(useCase: app(ClassifyExpenseUseCase::class));

    expect(ExpenseModel::query()->find($expense->id))->toBeNull();
    ExpenseClassificationAgent::assertNeverPrompted();
});

it('expires an unprocessed attempt without calling the provider', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $expense = createClassifiableExpense(userId: $userId, token: $token);
    $expense->classification_expires_at = now()->subSecond();
    $expense->save();

    (new ClassifyExpenseQueue(token: $expense->classification_token, expenseId: $expense->id, tries: 3, timeout: 15))
        ->handle(useCase: app(ClassifyExpenseUseCase::class));

    $expense->refresh();

    expect($expense->classification_token)->toBeNull();
    ExpenseClassificationAgent::assertNeverPrompted();
});

it('clears a pending attempt after all job retries fail', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $expense = createClassifiableExpense(userId: $userId, token: $token);

    (new ClassifyExpenseQueue(token: $expense->classification_token, expenseId: $expense->id, tries: 3, timeout: 15))
        ->failed();

    $expense->refresh();

    expect($expense->category)->toBe(ExpenseCategoryEnum::Other->value)
        ->and($expense->classification_token)->toBeNull();
});

it('keeps the expense when queue dispatch fails', function (): void {
    $this->app->instance(ExpenseClassificationDispatchPort::class, new class implements ExpenseClassificationDispatchPort
    {
        public function dispatch(string $token, int $expenseId): void
        {
            throw new RuntimeException('Queue unavailable.');
        }
    });
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $expense = createClassifiableExpense(userId: $userId, token: $token);

    expect($expense->category)->toBe(ExpenseCategoryEnum::Other->value)
        ->and($expense->classification_token)->toBeNull();
});

it('keeps other and clears the attempt when the queue push fails after commit', function (): void {
    Queue::beforePushing(callback: static function (): never {
        throw new RuntimeException('Queue unavailable.');
    });
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $expense = createClassifiableExpense(userId: $userId, token: $token);

    expect($expense->category)->toBe(ExpenseCategoryEnum::Other->value)
        ->and($expense->classification_token)->toBeNull();
    Queue::assertNothingPushed();
    ExpenseClassificationAgent::assertNeverPrompted();
});

it('does not run the provider during creation if the queue driver is sync', function (): void {
    config()->set('queue.default', 'sync');
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $expense = createClassifiableExpense(userId: $userId, token: $token);

    expect($expense->category)->toBe(ExpenseCategoryEnum::Other->value)
        ->and($expense->classification_token)->toBeNull();
    Queue::assertNothingPushed();
    ExpenseClassificationAgent::assertNeverPrompted();
});

it('keeps other and clears the attempt when the provider returns a category outside the enum', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $expense = createClassifiableExpense(userId: $userId, token: $token);
    ExpenseClassificationAgent::fake(responses: [['category' => 'unknown']]);

    (new ClassifyExpenseQueue(token: $expense->classification_token, expenseId: $expense->id, tries: 3, timeout: 15))
        ->handle(useCase: app(ClassifyExpenseUseCase::class));

    expect($expense->fresh()->category)->toBe(ExpenseCategoryEnum::Other->value)
        ->and($expense->fresh()->classification_token)->toBeNull();
    ExpenseClassificationAgent::assertPromptedTimes(times: 1);
});

it('keeps the expense until retries are exhausted when the provider throws', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $expense = createClassifiableExpense(userId: $userId, token: $token);
    ExpenseClassificationAgent::fake(responses: static function (string $prompt): never {
        throw new RuntimeException('Provider timed out.');
    });

    $job = new ClassifyExpenseQueue(token: $expense->classification_token, expenseId: $expense->id, tries: 3, timeout: 15);

    expect(fn () => $job->handle(useCase: app(ClassifyExpenseUseCase::class)))
        ->toThrow(RuntimeException::class, 'Provider timed out.');
    expect($expense->fresh()->category)->toBe(ExpenseCategoryEnum::Other->value)
        ->and($expense->fresh()->classification_token)->not->toBeNull();

    $job->failed();

    expect($expense->fresh()->category)->toBe(ExpenseCategoryEnum::Other->value)
        ->and($expense->fresh()->classification_token)->toBeNull();
});

it('does not overwrite an explicit category committed while the provider was responding', function (string $category): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $expense = createClassifiableExpense(userId: $userId, token: $token);
    $classificationToken = $expense->classification_token;
    ExpenseClassificationAgent::fake(responses: function (string $prompt) use ($token, $expense, $category): array {
        withToken($token)->patchJson(route('expenses.update', $expense), [
            'data' => [
                'type' => 'expenses',
                'attributes' => ['category' => $category],
            ],
        ])->assertOk();

        return ['category' => 'food'];
    });

    (new ClassifyExpenseQueue(token: $classificationToken, expenseId: $expense->id, tries: 3, timeout: 15))
        ->handle(useCase: app(ClassifyExpenseUseCase::class));

    expect($expense->fresh()->category)->toBe($category)
        ->and($expense->fresh()->classification_token)->toBeNull();
    ExpenseClassificationAgent::assertPromptedTimes(times: 1);
})->with(['health', 'other']);

it('processes a database-queued classification using the real queue worker', function (): void {
    config()->set('queue.default', 'database');
    Queue::swap(instance: Queue::getFacadeRoot()->queue);
    ExpenseClassificationAgent::fake(responses: [['category' => 'food']]);
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $expense = createClassifiableExpense(userId: $userId, token: $token);

    expect(DB::table('jobs')->where('queue', config('expense.classification.queue'))->count())->toBe(1)
        ->and($expense->category)->toBe(ExpenseCategoryEnum::Other->value);
    ExpenseClassificationAgent::assertNeverPrompted();

    Artisan::call(command: 'queue:work', parameters: [
        'connection' => 'database',
        '--queue' => config('expense.classification.queue'),
        '--once' => true,
    ]);

    expect($expense->fresh()->category)->toBe(ExpenseCategoryEnum::Food->value)
        ->and($expense->fresh()->classification_token)->toBeNull()
        ->and(DB::table('jobs')->where('queue', config('expense.classification.queue'))->count())->toBe(0);
    ExpenseClassificationAgent::assertPromptedTimes(times: 1);
});

it('keeps the cached list on rollback and invalidates it after a committed creation', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    withToken($token)->getJson(route('expenses.index'))->assertOk()->assertJsonCount(0, 'data');

    try {
        DB::transaction(callback: function () use ($token): void {
            withToken($token)->postJson(route('expenses.create'), [
                'data' => [
                    'type' => 'expenses',
                    'attributes' => ['amount' => 1500, 'description' => 'Mercado - 2 itens'],
                ],
            ])->assertCreated();

            throw new RuntimeException('Rollback.');
        });
    } catch (RuntimeException) {
    }

    expect(ExpenseModel::query()->where('user_id', $userId)->exists())->toBeFalse();
    withToken($token)->getJson(route('expenses.index'))->assertOk()->assertJsonCount(0, 'data');

    createClassifiableExpense(userId: $userId, token: $token);

    withToken($token)->getJson(route('expenses.index'))->assertOk()->assertJsonCount(1, 'data');
});

it('refreshes the owner cached page only after a real classification commits', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $expense = createClassifiableExpense(userId: $userId, token: $token);

    withToken($token)->getJson(route('expenses.index'))
        ->assertOk()->assertJsonPath('data.0.attributes.category', 'other');

    $repository = app(ExpenseCategorizationRepository::class);

    try {
        DB::transaction(function () use ($repository, $expense, $token): void {
            expect($repository->applyClassificationAttempt(new ApplyExpenseClassificationInput(
                expenseId: $expense->id,
                token: $expense->classification_token,
                description: $expense->description,
                category: ExpenseCategoryEnum::Food,
            )))->toBe($expense->user_id);

            expect($expense->fresh()->category)->toBe('food');
            withToken($token)->getJson(route('expenses.index'))
                ->assertOk()->assertJsonPath('data.0.attributes.category', 'other');

            throw new RuntimeException('Rollback.');
        });
    } catch (RuntimeException) {
    }

    expect($expense->fresh()->category)->toBe('other');
    withToken($token)->getJson(route('expenses.index'))
        ->assertOk()->assertJsonPath('data.0.attributes.category', 'other');

    DB::transaction(function () use ($repository, $expense, $token): void {
        expect($repository->applyClassificationAttempt(new ApplyExpenseClassificationInput(
            expenseId: $expense->id,
            token: $expense->classification_token,
            description: $expense->description,
            category: ExpenseCategoryEnum::Food,
        )))->toBe($expense->user_id);

        withToken($token)->getJson(route('expenses.index'))
            ->assertOk()->assertJsonPath('data.0.attributes.category', 'other');
    });

    expect($expense->fresh()->category)->toBe('food')
        ->and($expense->fresh()->classification_token)->toBeNull();
    withToken($token)->getJson(route('expenses.index'))
        ->assertOk()->assertJsonPath('data.0.attributes.category', 'food');
});
