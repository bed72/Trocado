<?php

declare(strict_types=1);

namespace App\Budget\Application\UseCases;

use App\Budget\Application\Ports\BudgetWritePort;
use App\Budget\Application\Repositories\BudgetRecurrenceRepository;
use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\Exceptions\InvalidBudgetRecurrenceException;
use DateTimeImmutable;

final readonly class GenerateDueBudgetRecurrencesUseCase
{
    public function __construct(
        private BudgetWritePort $port,
        private BudgetRepository $budgetRepository,
        private BudgetRecurrenceRepository $recurrenceRepository,
    ) {}

    public function execute(string $processingDate): int
    {
        $date = DateTimeImmutable::createFromFormat(format: '!Y-m-d', datetime: $processingDate);

        if ($date === false || $date->format(format: 'Y-m-d') !== $processingDate) {
            throw new InvalidBudgetRecurrenceException(message: 'A data de processamento deve ser válida.');
        }

        $generated = 0;

        foreach ($this->recurrenceRepository->findActiveDueIds(processingDate: $processingDate) as $recurrenceId) {
            while ($this->generateNextOccurrence(recurrenceId: $recurrenceId, processingDate: $processingDate)) {
                $generated++;
            }
        }

        return $generated;
    }

    private function generateNextOccurrence(int $recurrenceId, string $processingDate): bool
    {
        return $this->port->execute(operation: function () use ($recurrenceId, $processingDate): bool {
            $recurrence = $this->recurrenceRepository->findByIdForUpdate(id: $recurrenceId);

            if ($recurrence === null || ! $recurrence->isDue(processingDate: $processingDate)) {
                return false;
            }

            $interval = $recurrence->pendingInterval();

            if ($this->budgetRepository->hasOverlap(
                endDate: $interval['endDate'],
                startDate: $interval['startDate'],
            )) {
                $this->recurrenceRepository->create(recurrence: $recurrence->block(
                    blockedAt: new DateTimeImmutable(datetime: $processingDate),
                ));

                return false;
            }

            $this->budgetRepository->create(budget: new BudgetEntity(
                id: null,
                amount: $recurrence->amount,
                endDate: $interval['endDate'],
                recurrenceId: $recurrence->id,
                startDate: $interval['startDate'],
            ));
            $this->recurrenceRepository->create(recurrence: $recurrence->advanceToNextInterval());

            return true;
        });
    }
}
