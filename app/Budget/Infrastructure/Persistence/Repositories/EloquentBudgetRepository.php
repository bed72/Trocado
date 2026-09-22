<?php

declare(strict_types=1);

namespace App\Budget\Infrastructure\Persistence\Repositories;

use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\ValueObjects\MoneyValueObject;
use App\Budget\Infrastructure\Persistence\Models\BudgetModel;
use DateTimeImmutable;

final class EloquentBudgetRepository implements BudgetRepository
{
    public function create(BudgetEntity $budget): BudgetEntity
    {
        $model = $budget->id === null
            ? new BudgetModel
            : BudgetModel::query()->findOrFail(id: $budget->id);

        $model->fill(attributes: [
            'end_date' => $budget->endDate,
            'start_date' => $budget->startDate,
            'amount' => $budget->amount->cents(),
            'recurrence_id' => $budget->recurrenceId,
        ]);
        $model->save();

        return $this->toEntity(model: $model);
    }

    public function findById(int $id): ?BudgetEntity
    {
        $model = BudgetModel::query()->find(id: $id);

        return $model === null ? null : $this->toEntity(model: $model);
    }

    public function all(): array
    {
        return BudgetModel::query()->orderBy(column: 'id')->get()
            ->map(callback: function (BudgetModel $model): BudgetEntity {
                return $this->toEntity(model: $model);
            })
            ->all();
    }

    public function delete(int $id): bool
    {
        return BudgetModel::query()->whereKey(id: $id)->delete() > 0;
    }

    public function hasOverlap(string $startDate, string $endDate, ?int $excludeId = null): bool
    {
        $query = BudgetModel::query()
            ->whereDate(column: 'start_date', operator: '<=', value: $endDate)
            ->whereDate(column: 'end_date', operator: '>=', value: $startDate);

        if ($excludeId !== null) {
            $query->whereKeyNot(id: $excludeId);
        }

        return $query->exists();
    }

    private function toEntity(BudgetModel $model): BudgetEntity
    {
        return new BudgetEntity(
            id: (int) $model->getKey(),
            endDate: $model->end_date->format(format: 'Y-m-d'),
            startDate: $model->start_date->format(format: 'Y-m-d'),
            amount: MoneyValueObject::fromCents(cents: $model->amount),
            createdAt: $model->created_at === null ? null : DateTimeImmutable::createFromInterface(object: $model->created_at),
            updatedAt: $model->updated_at === null ? null : DateTimeImmutable::createFromInterface(object: $model->updated_at),
            recurrenceId: $model->recurrence_id,
        );
    }
}
