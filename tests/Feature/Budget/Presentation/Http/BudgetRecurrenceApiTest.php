<?php

declare(strict_types=1);

use App\Budget\Application\Ports\BudgetWritePort;
use App\Budget\Application\Repositories\BudgetRecurrenceRepository;
use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Application\UseCases\CreateBudgetUseCase;
use App\Budget\Application\UseCases\GenerateDueBudgetRecurrencesUseCase;
use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\Entities\BudgetRecurrenceEntity;
use App\Budget\Domain\Exceptions\InvalidBudgetRecurrenceException;
use App\Budget\Infrastructure\Persistence\Models\BudgetModel;
use App\Budget\Infrastructure\Persistence\Models\BudgetRecurrenceModel;
use Illuminate\Database\QueryException;

it('creates a simple budget by default without a recurrence relationship', function (): void {
    $response = $this->postJson('/api/budgets', recurrenceBudgetPayload());

    $response->assertCreated()
        ->assertJsonMissingPath('data.relationships.recurrence');
    $this->assertDatabaseCount('budget_recurrences', 0);
    $this->assertDatabaseHas('budgets', ['recurrence_id' => null]);
});

it('creates a simple budget when recurrence is explicitly false', function (): void {
    $payload = recurrenceBudgetPayload();
    $payload['data']['attributes']['recurring'] = false;

    $this->postJson('/api/budgets', $payload)
        ->assertCreated()
        ->assertJsonMissingPath('data.relationships.recurrence');

    $this->assertDatabaseCount('budget_recurrences', 0);
});

it('creates a recurrence and its initial budget atomically', function (): void {
    $payload = recurrenceBudgetPayload();
    $payload['data']['attributes']['recurring'] = true;

    $response = $this->postJson('/api/budgets', $payload)
        ->assertCreated()
        ->assertJsonPath('data.relationships.recurrence.data.type', 'budget-recurrences');

    $recurrenceId = $response->json('data.relationships.recurrence.data.id');
    expect($recurrenceId)->toBeString();
    $this->assertDatabaseHas('budget_recurrences', [
        'id' => $recurrenceId,
        'amount' => 1000,
        'status' => 'active',
        'duration_in_days' => 7,
        'next_start_date' => '2026-01-08 00:00:00',
    ]);
    $this->assertDatabaseHas('budgets', [
        'recurrence_id' => $recurrenceId,
        'end_date' => '2026-01-07 00:00:00',
        'start_date' => '2026-01-01 00:00:00',
    ]);
});

it('respects sparse fieldsets when exposing the recurrence relationship', function (): void {
    $payload = recurrenceBudgetPayload();
    $payload['data']['attributes']['recurring'] = true;

    $this->postJson('/api/budgets?fields[budgets]=amount', $payload)
        ->assertCreated()
        ->assertJsonPath('data.attributes.amount', 1000)
        ->assertJsonMissingPath('data.relationships.recurrence');
});

it('includes the recurrence relationship when a sparse fieldset requests it', function (): void {
    $payload = recurrenceBudgetPayload();
    $payload['data']['attributes']['recurring'] = true;

    $this->postJson('/api/budgets?fields[budgets]=amount,recurrence', $payload)
        ->assertCreated()
        ->assertJsonPath('data.relationships.recurrence.data.type', 'budget-recurrences');
});

it('rejects non-boolean recurrence values', function (mixed $recurring): void {
    $payload = recurrenceBudgetPayload();
    $payload['data']['attributes']['recurring'] = $recurring;

    $this->postJson('/api/budgets', $payload)
        ->assertUnprocessable()
        ->assertJsonFragment(['source' => ['pointer' => '/data/attributes/recurring']]);

    $this->assertDatabaseCount('budgets', 0);
    $this->assertDatabaseCount('budget_recurrences', 0);
})->with([0, 1, 'true', 'false']);

it('rolls back the recurrence when its initial budget cannot be persisted', function (): void {
    $failingBudgetRepository = new class implements BudgetRepository
    {
        public function all(): array
        {
            return [];
        }

        public function delete(int $id): bool
        {
            return false;
        }

        public function findById(int $id): ?BudgetEntity
        {
            return null;
        }

        public function hasOverlap(string $startDate, string $endDate, ?int $excludeId = null): bool
        {
            return false;
        }

        public function save(BudgetEntity $budget): BudgetEntity
        {
            throw new RuntimeException('Falha de persistência simulada.');
        }
    };

    expect(fn () => (new CreateBudgetUseCase(
        port: app(BudgetWritePort::class),
        budgetRepository: $failingBudgetRepository,
        recurrenceRepository: app(BudgetRecurrenceRepository::class),
    ))->execute(
        amount: 1000,
        recurring: true,
        endDate: '2026-01-07',
        startDate: '2026-01-01',
    ))->toThrow(RuntimeException::class);

    $this->assertDatabaseCount('budget_recurrences', 0);
    $this->assertDatabaseCount('budgets', 0);
});

it('does not persist a budget when recurrence persistence fails', function (): void {
    $failingRecurrenceRepository = new class implements BudgetRecurrenceRepository
    {
        public function findById(int $id): ?BudgetRecurrenceEntity
        {
            return null;
        }

        public function findByIdForUpdate(int $id): ?BudgetRecurrenceEntity
        {
            return null;
        }

        public function findActiveDueIds(string $processingDate): array
        {
            return [];
        }

        public function save(BudgetRecurrenceEntity $recurrence): BudgetRecurrenceEntity
        {
            throw new RuntimeException('Falha de persistência simulada.');
        }
    };

    expect(fn () => (new CreateBudgetUseCase(
        port: app(BudgetWritePort::class),
        budgetRepository: app(BudgetRepository::class),
        recurrenceRepository: $failingRecurrenceRepository,
    ))->execute(
        amount: 1000,
        recurring: true,
        endDate: '2026-01-07',
        startDate: '2026-01-01',
    ))->toThrow(RuntimeException::class);

    $this->assertDatabaseCount('budget_recurrences', 0);
    $this->assertDatabaseCount('budgets', 0);
});

it('rejects overlapping creates and updates while accepting adjacent intervals', function (): void {
    $first = BudgetModel::query()->create([
        'amount' => 1000,
        'start_date' => '2026-01-01',
        'end_date' => '2026-01-07',
    ]);

    $overlap = recurrenceBudgetPayload(startDate: '2026-01-07', endDate: '2026-01-10');
    $this->postJson('/api/budgets', $overlap)
        ->assertConflict()
        ->assertJsonPath('errors.0.title', 'Conflito de datas');

    $adjacent = recurrenceBudgetPayload(startDate: '2026-01-08', endDate: '2026-01-14');
    $secondId = $this->postJson('/api/budgets', $adjacent)->assertCreated()->json('data.id');

    $this->patchJson("/api/budgets/{$secondId}", [
        'data' => [
            'type' => 'budgets',
            'id' => (string) $secondId,
            'attributes' => ['start_date' => '2026-01-07'],
        ],
    ])->assertConflict();

    $this->assertDatabaseHas('budgets', [
        'id' => $first->getKey(),
        'start_date' => '2026-01-01 00:00:00',
        'end_date' => '2026-01-07 00:00:00',
    ]);
    $this->assertDatabaseHas('budgets', [
        'id' => $secondId,
        'start_date' => '2026-01-08 00:00:00',
        'end_date' => '2026-01-14 00:00:00',
    ]);
});

it('generates every due occurrence chronologically and is idempotent', function (): void {
    $budget = createRecurringBudget();
    $useCase = app(GenerateDueBudgetRecurrencesUseCase::class);

    expect($useCase->execute(processingDate: '2026-01-07'))->toBe(0)
        ->and($useCase->execute(processingDate: '2026-01-22'))->toBe(3)
        ->and($useCase->execute(processingDate: '2026-01-22'))->toBe(0);

    expect(BudgetModel::query()->where('recurrence_id', $budget->recurrenceId)->orderBy('start_date')->get()
        ->map(fn (BudgetModel $model): array => [
            $model->start_date->format('Y-m-d'),
            $model->end_date->format('Y-m-d'),
        ])->all())->toBe([
            ['2026-01-01', '2026-01-07'],
            ['2026-01-08', '2026-01-14'],
            ['2026-01-15', '2026-01-21'],
            ['2026-01-22', '2026-01-28'],
        ]);
    $occurrences = BudgetModel::query()->where('recurrence_id', $budget->recurrenceId)->get();
    expect($occurrences->pluck('id')->unique())->toHaveCount(4)
        ->and($occurrences->every(fn (BudgetModel $model): bool => $model->created_at !== null && $model->updated_at !== null))->toBeTrue();
    $this->assertDatabaseHas('budget_recurrences', [
        'id' => $budget->recurrenceId,
        'next_start_date' => '2026-01-29 00:00:00',
    ]);
});

it('rejects an invalid explicit processing date', function (): void {
    expect(fn () => app(GenerateDueBudgetRecurrencesUseCase::class)->execute(processingDate: '2026-02-30'))
        ->toThrow(InvalidBudgetRecurrenceException::class);
});

it('rolls back only the unconfirmed occurrence and resumes from its cursor', function (): void {
    $budget = createRecurringBudget();
    $repository = app(BudgetRecurrenceRepository::class);
    $failingRepository = new class($repository) implements BudgetRecurrenceRepository
    {
        public function __construct(private readonly BudgetRecurrenceRepository $repository) {}

        public function findById(int $id): ?BudgetRecurrenceEntity
        {
            return $this->repository->findById(id: $id);
        }

        public function findByIdForUpdate(int $id): ?BudgetRecurrenceEntity
        {
            return $this->repository->findByIdForUpdate(id: $id);
        }

        public function findActiveDueIds(string $processingDate): array
        {
            return $this->repository->findActiveDueIds(processingDate: $processingDate);
        }

        public function save(BudgetRecurrenceEntity $recurrence): BudgetRecurrenceEntity
        {
            if ($recurrence->nextStartDate === '2026-01-22') {
                throw new RuntimeException('Falha de persistência simulada.');
            }

            return $this->repository->save(recurrence: $recurrence);
        }
    };
    $useCase = new GenerateDueBudgetRecurrencesUseCase(
        port: app(BudgetWritePort::class),
        recurrenceRepository: $failingRepository,
        budgetRepository: app(BudgetRepository::class),
    );

    expect(fn () => $useCase->execute(processingDate: '2026-01-22'))
        ->toThrow(RuntimeException::class);

    $this->assertDatabaseHas('budgets', [
        'start_date' => '2026-01-08 00:00:00',
        'recurrence_id' => $budget->recurrenceId,
    ]);
    $this->assertDatabaseMissing('budgets', [
        'start_date' => '2026-01-15 00:00:00',
        'recurrence_id' => $budget->recurrenceId,
    ]);
    $this->assertDatabaseHas('budget_recurrences', [
        'id' => $budget->recurrenceId,
        'next_start_date' => '2026-01-15 00:00:00',
    ]);

    expect(app(GenerateDueBudgetRecurrencesUseCase::class)->execute(processingDate: '2026-01-22'))->toBe(2);
    $this->assertDatabaseHas('budget_recurrences', [
        'id' => $budget->recurrenceId,
        'next_start_date' => '2026-01-29 00:00:00',
    ]);
});

it('blocks a conflicting recurrence without advancing and resumes only after resolution', function (): void {
    $budget = createRecurringBudget();
    $conflict = BudgetModel::query()->create([
        'amount' => 500,
        'start_date' => '2026-01-08',
        'end_date' => '2026-01-14',
    ]);
    $useCase = app(GenerateDueBudgetRecurrencesUseCase::class);

    expect($useCase->execute(processingDate: '2026-01-08'))->toBe(0);
    $this->assertDatabaseHas('budget_recurrences', [
        'id' => $budget->recurrenceId,
        'status' => 'blocked',
        'next_start_date' => '2026-01-08 00:00:00',
    ]);
    $this->assertDatabaseCount('budgets', 2);
    expect($useCase->execute(processingDate: '2026-01-15'))->toBe(0);
    $this->assertDatabaseCount('budgets', 2);

    $this->postJson("/api/budget-recurrences/{$budget->recurrenceId}/resume")
        ->assertConflict();

    $conflict->delete();
    $this->postJson("/api/budget-recurrences/{$budget->recurrenceId}/resume")
        ->assertOk()
        ->assertJsonPath('data.attributes.status', 'active')
        ->assertJsonPath('data.attributes.next_start_date', '2026-01-08');

    expect($useCase->execute(processingDate: '2026-01-08'))->toBe(1);
    $this->assertDatabaseHas('budgets', [
        'recurrence_id' => $budget->recurrenceId,
        'start_date' => '2026-01-08 00:00:00',
    ]);
});

it('exposes and updates only the future recurrence template', function (): void {
    $budget = createRecurringBudget();

    $this->getJson("/api/budget-recurrences/{$budget->recurrenceId}")
        ->assertOk()
        ->assertJsonPath('data.type', 'budget-recurrences')
        ->assertJsonPath('data.attributes.amount', 1000)
        ->assertJsonPath('data.attributes.duration_in_days', 7)
        ->assertJsonPath('data.attributes.next_start_date', '2026-01-08');

    $this->patchJson("/api/budget-recurrences/{$budget->recurrenceId}", recurrenceUpdatePayload(
        id: $budget->recurrenceId,
        attributes: ['amount' => 2500, 'duration_in_days' => 3],
    ))->assertOk()
        ->assertJsonPath('data.attributes.amount', 2500)
        ->assertJsonPath('data.attributes.duration_in_days', 3)
        ->assertJsonPath('data.attributes.next_start_date', '2026-01-08');

    app(GenerateDueBudgetRecurrencesUseCase::class)->execute(processingDate: '2026-01-08');

    $this->assertDatabaseHas('budgets', [
        'id' => $budget->id,
        'amount' => 1000,
        'start_date' => '2026-01-01 00:00:00',
        'end_date' => '2026-01-07 00:00:00',
    ]);
    $this->assertDatabaseHas('budgets', [
        'recurrence_id' => $budget->recurrenceId,
        'amount' => 2500,
        'start_date' => '2026-01-08 00:00:00',
        'end_date' => '2026-01-10 00:00:00',
    ]);
});

it('returns recurrence API errors for missing resources and invalid updates', function (): void {
    $this->getJson('/api/budget-recurrences/99999')
        ->assertNotFound()
        ->assertJsonPath('errors.0.title', 'Recorrência não encontrada');
    $this->patchJson('/api/budget-recurrences/99999', recurrenceUpdatePayload(
        id: 99999,
        attributes: ['amount' => 2000],
    ))->assertNotFound()
        ->assertJsonPath('errors.0.title', 'Recorrência não encontrada');
    $this->postJson('/api/budget-recurrences/99999/end')
        ->assertNotFound()
        ->assertJsonPath('errors.0.title', 'Recorrência não encontrada');
    $this->postJson('/api/budget-recurrences/99999/resume')
        ->assertNotFound()
        ->assertJsonPath('errors.0.title', 'Recorrência não encontrada');

    $budget = createRecurringBudget();
    $this->patchJson("/api/budget-recurrences/{$budget->recurrenceId}", recurrenceUpdatePayload(
        id: $budget->recurrenceId,
        attributes: ['duration_in_days' => 0],
    ))->assertUnprocessable()
        ->assertJsonFragment(['source' => ['pointer' => '/data/attributes/duration_in_days']]);

    $this->patchJson("/api/budget-recurrences/{$budget->recurrenceId}", recurrenceUpdatePayload(
        id: $budget->recurrenceId,
        attributes: ['unexpected' => true],
    ))->assertUnprocessable()
        ->assertJsonFragment(['source' => ['pointer' => '/data/attributes']]);
});

it('ends active and blocked recurrences irreversibly without deleting budgets', function (bool $blocked): void {
    $budget = createRecurringBudget();

    if ($blocked) {
        BudgetRecurrenceModel::query()->whereKey($budget->recurrenceId)->update([
            'status' => 'blocked',
            'blocked_at' => now(),
        ]);
    }

    $this->postJson("/api/budget-recurrences/{$budget->recurrenceId}/end")
        ->assertOk()
        ->assertJsonPath('data.attributes.status', 'ended');

    expect(app(GenerateDueBudgetRecurrencesUseCase::class)->execute(processingDate: '2026-02-01'))->toBe(0);
    $this->postJson("/api/budget-recurrences/{$budget->recurrenceId}/resume")
        ->assertConflict();
    $this->patchJson("/api/budget-recurrences/{$budget->recurrenceId}", recurrenceUpdatePayload(
        id: $budget->recurrenceId,
        attributes: ['amount' => 2000],
    ))->assertConflict();
    $this->assertDatabaseHas('budgets', ['id' => $budget->id]);
})->with([false, true]);

it('keeps occurrence edits and deletion isolated from its recurrence', function (): void {
    $budget = createRecurringBudget();
    app(GenerateDueBudgetRecurrencesUseCase::class)->execute(processingDate: '2026-01-08');
    $occurrence = BudgetModel::query()
        ->where('recurrence_id', $budget->recurrenceId)
        ->whereDate('start_date', '2026-01-08')
        ->sole();

    $this->patchJson("/api/budgets/{$occurrence->getKey()}", [
        'data' => [
            'type' => 'budgets',
            'id' => (string) $occurrence->getKey(),
            'attributes' => ['amount' => 9999, 'end_date' => '2026-01-13'],
        ],
    ])->assertOk();
    $this->assertDatabaseHas('budget_recurrences', [
        'id' => $budget->recurrenceId,
        'amount' => 1000,
        'duration_in_days' => 7,
        'next_start_date' => '2026-01-15 00:00:00',
    ]);

    $this->deleteJson("/api/budgets/{$occurrence->getKey()}")->assertNoContent();
    expect(app(GenerateDueBudgetRecurrencesUseCase::class)->execute(processingDate: '2026-01-14'))->toBe(0);
    $this->assertDatabaseMissing('budgets', ['id' => $occurrence->getKey()]);
});

it('enforces one occurrence per recurrence and start date in the database', function (): void {
    $budget = createRecurringBudget();

    expect(fn () => BudgetModel::query()->create([
        'amount' => 1000,
        'start_date' => '2026-01-01',
        'end_date' => '2026-01-07',
        'recurrence_id' => $budget->recurrenceId,
    ]))->toThrow(QueryException::class);

    $this->assertDatabaseCount('budgets', 1);
});

function recurrenceBudgetPayload(string $startDate = '2026-01-01', string $endDate = '2026-01-07'): array
{
    return [
        'data' => [
            'type' => 'budgets',
            'attributes' => [
                'amount' => 1000,
                'start_date' => $startDate,
                'end_date' => $endDate,
            ],
        ],
    ];
}

function recurrenceUpdatePayload(int $id, array $attributes): array
{
    return [
        'data' => [
            'type' => 'budget-recurrences',
            'id' => (string) $id,
            'attributes' => $attributes,
        ],
    ];
}

function createRecurringBudget(): BudgetEntity
{
    return app(CreateBudgetUseCase::class)->execute(
        amount: 1000,
        startDate: '2026-01-01',
        endDate: '2026-01-07',
        recurring: true,
    );
}
