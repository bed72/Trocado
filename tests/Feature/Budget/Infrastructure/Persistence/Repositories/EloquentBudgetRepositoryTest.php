<?php

declare(strict_types=1);

use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\ValueObjects\MoneyValueObject;
use App\Budget\Infrastructure\Persistence\Models\BudgetModel;
use App\Budget\Infrastructure\Persistence\Repositories\EloquentBudgetRepository;
use Illuminate\Support\Facades\DB;

it('persists and maps a new budget entity', function (): void {
    $repository = new EloquentBudgetRepository;

    $persisted = $repository->create(budget: new BudgetEntity(
        id: null,
        endDate: '2026-09-30',
        startDate: '2026-09-01',
        amount: MoneyValueObject::fromCents(cents: 12500),
    ));

    expect($persisted->id)->toBeInt()
        ->and($persisted->amount->cents())->toBe(12500)
        ->and($persisted->startDate)->toBe('2026-09-01')
        ->and($persisted->endDate)->toBe('2026-09-30')
        ->and($persisted->createdAt)->toBeInstanceOf(DateTimeImmutable::class)
        ->and($persisted->updatedAt)->toBeInstanceOf(DateTimeImmutable::class);

    $this->assertDatabaseHas('budgets', [
        'id' => $persisted->id,
        'amount' => 12500,
        'start_date' => '2026-09-01 00:00:00',
        'end_date' => '2026-09-30 00:00:00',
    ]);
});

it('updates an existing budget without inserting another row', function (): void {
    $model = BudgetModel::query()->create([
        'amount' => 12500,
        'start_date' => '2026-09-01',
        'end_date' => '2026-09-30',
    ]);
    $repository = new EloquentBudgetRepository;

    $updated = $repository->create(budget: new BudgetEntity(
        id: (int) $model->getKey(),
        endDate: '2026-10-31',
        startDate: '2026-10-01',
        amount: MoneyValueObject::fromCents(cents: 25000),
    ));

    expect($updated->id)->toBe((int) $model->getKey())
        ->and($updated->amount->cents())->toBe(25000)
        ->and($updated->startDate)->toBe('2026-10-01')
        ->and($updated->endDate)->toBe('2026-10-31');
    $this->assertDatabaseCount('budgets', 1);
    $this->assertDatabaseHas('budgets', ['id' => $model->getKey(), 'amount' => 25000]);
});

it('finds a budget and returns null when it is absent', function (): void {
    $model = BudgetModel::query()->create([
        'amount' => 12500,
        'start_date' => '2026-09-01',
        'end_date' => '2026-09-30',
    ]);
    $repository = new EloquentBudgetRepository;

    $found = $repository->findById(id: (int) $model->getKey());

    expect($found)->not->toBeNull()
        ->and($found->id)->toBe((int) $model->getKey())
        ->and($found->amount->cents())->toBe(12500)
        ->and($repository->findById(id: 99999))->toBeNull();
});

it('lists budgets in ID order and returns an empty list when none exist', function (): void {
    $repository = new EloquentBudgetRepository;

    expect($repository->all())->toBe([]);

    $first = BudgetModel::query()->create([
        'amount' => 12500,
        'start_date' => '2026-09-01',
        'end_date' => '2026-09-30',
    ]);
    $second = BudgetModel::query()->create([
        'amount' => 25000,
        'start_date' => '2026-10-01',
        'end_date' => '2026-10-31',
    ]);

    $budgets = $repository->all();

    expect($budgets)->toHaveCount(2)
        ->and($budgets[0]->id)->toBe((int) $first->getKey())
        ->and($budgets[1]->id)->toBe((int) $second->getKey());
});

it('maps nullable timestamps', function (): void {
    $id = DB::table('budgets')->insertGetId([
        'amount' => 12500,
        'start_date' => '2026-09-01',
        'end_date' => '2026-09-30',
        'created_at' => null,
        'updated_at' => null,
    ]);

    $budget = (new EloquentBudgetRepository)->findById(id: $id);

    expect($budget)->not->toBeNull()
        ->and($budget->createdAt)->toBeNull()
        ->and($budget->updatedAt)->toBeNull();
});

it('reports whether a budget was deleted', function (): void {
    $model = BudgetModel::query()->create([
        'amount' => 12500,
        'start_date' => '2026-09-01',
        'end_date' => '2026-09-30',
    ]);
    $repository = new EloquentBudgetRepository;

    expect($repository->delete(id: (int) $model->getKey()))->toBeTrue()
        ->and($repository->delete(id: (int) $model->getKey()))->toBeFalse();
});
