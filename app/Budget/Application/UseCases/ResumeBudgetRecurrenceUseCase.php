<?php

declare(strict_types=1);

namespace App\Budget\Application\UseCases;

use App\Budget\Application\Exceptions\BudgetRecurrenceNotFoundException;
use App\Budget\Application\Ports\BudgetWritePort;
use App\Budget\Application\Repositories\BudgetRecurrenceRepository;
use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Domain\Entities\BudgetRecurrenceEntity;
use App\Budget\Domain\Exceptions\OverlappingBudgetException;

final readonly class ResumeBudgetRecurrenceUseCase
{
    public function __construct(
        private BudgetWritePort $port,
        private BudgetRepository $budgetRepository,
        private BudgetRecurrenceRepository $recurrenceRepository,
    ) {}

    public function execute(int $id): BudgetRecurrenceEntity
    {
        return $this->port->execute(operation: function () use ($id): BudgetRecurrenceEntity {
            $recurrence = $this->recurrenceRepository->findByIdForUpdate(id: $id)
                ?? throw new BudgetRecurrenceNotFoundException(id: $id);
            $interval = $recurrence->pendingInterval();

            if ($this->budgetRepository->hasOverlap(
                endDate: $interval['endDate'],
                startDate: $interval['startDate'],
            )) {
                throw new OverlappingBudgetException;
            }

            return $this->recurrenceRepository->save(recurrence: $recurrence->resume());
        });
    }
}
