<?php

declare(strict_types=1);

namespace App\Budget\Infrastructure\Persistence\Repositories;

use App\Budget\Application\Repositories\BudgetRecurrenceRepository;
use App\Budget\Domain\Entities\BudgetRecurrenceEntity;
use App\Budget\Domain\Enums\RecurrenceStatusEnum;
use App\Budget\Domain\ValueObjects\MoneyValueObject;
use App\Budget\Infrastructure\Persistence\Models\BudgetRecurrenceModel;
use DateTimeImmutable;

final class EloquentBudgetRecurrenceRepository implements BudgetRecurrenceRepository
{
    public function save(BudgetRecurrenceEntity $recurrence): BudgetRecurrenceEntity
    {
        $model = $recurrence->id === null
            ? new BudgetRecurrenceModel
            : BudgetRecurrenceModel::query()->findOrFail(id: $recurrence->id);

        $model->fill(attributes: [
            'ended_at' => $recurrence->endedAt,
            'status' => $recurrence->status->value,
            'blocked_at' => $recurrence->blockedAt,
            'amount' => $recurrence->amount->cents(),
            'next_start_date' => $recurrence->nextStartDate,
            'duration_in_days' => $recurrence->durationInDays,
        ]);
        $model->save();

        return $this->toEntity(model: $model);
    }

    public function findById(int $id): ?BudgetRecurrenceEntity
    {
        $model = BudgetRecurrenceModel::query()->find(id: $id);

        return $model === null ? null : $this->toEntity(model: $model);
    }

    public function findByIdForUpdate(int $id): ?BudgetRecurrenceEntity
    {
        $model = BudgetRecurrenceModel::query()->lockForUpdate()->find(id: $id);

        return $model === null ? null : $this->toEntity(model: $model);
    }

    public function findActiveDueIds(string $processingDate): array
    {
        return BudgetRecurrenceModel::query()
            ->where(column: 'status', operator: RecurrenceStatusEnum::Active->value)
            ->whereDate(column: 'next_start_date', operator: '<=', value: $processingDate)
            ->orderBy(column: 'next_start_date')
            ->orderBy(column: 'id')
            ->pluck(column: 'id')
            ->map(callback: fn (mixed $id): int => (int) $id)
            ->all();
    }

    private function toEntity(BudgetRecurrenceModel $model): BudgetRecurrenceEntity
    {
        return new BudgetRecurrenceEntity(
            id: (int) $model->getKey(),
            durationInDays: $model->duration_in_days,
            status: RecurrenceStatusEnum::from(value: $model->status),
            amount: MoneyValueObject::fromCents(cents: $model->amount),
            nextStartDate: $model->next_start_date->format(format: 'Y-m-d'),
            endedAt: $model->ended_at === null ? null : DateTimeImmutable::createFromInterface(object: $model->ended_at),
            createdAt: $model->created_at === null ? null : DateTimeImmutable::createFromInterface(object: $model->created_at),
            updatedAt: $model->updated_at === null ? null : DateTimeImmutable::createFromInterface(object: $model->updated_at),
            blockedAt: $model->blocked_at === null ? null : DateTimeImmutable::createFromInterface(object: $model->blocked_at),
        );
    }
}
