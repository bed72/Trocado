<?php

declare(strict_types=1);

namespace App\Budget\Application\Repositories;

use App\Budget\Domain\Entities\BudgetRecurrenceEntity;

interface BudgetRecurrenceRepository
{
    public function findById(int $id): ?BudgetRecurrenceEntity;

    /** @return list<int> */
    public function findActiveDueIds(string $processingDate): array;

    public function findByIdForUpdate(int $id): ?BudgetRecurrenceEntity;

    public function save(BudgetRecurrenceEntity $recurrence): BudgetRecurrenceEntity;
}
