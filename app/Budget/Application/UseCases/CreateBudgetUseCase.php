<?php

declare(strict_types=1);

namespace App\Budget\Application\UseCases;

use App\Budget\Application\Ports\BudgetWritePort;
use App\Budget\Application\Repositories\BudgetRecurrenceRepository;
use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\Entities\BudgetRecurrenceEntity;
use App\Budget\Domain\Exceptions\OverlappingBudgetException;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

final readonly class CreateBudgetUseCase
{
    public function __construct(
        private BudgetWritePort $port,
        private BudgetRepository $budgetRepository,
        private BudgetRecurrenceRepository $recurrenceRepository,
    ) {}

    public function execute(int $amount, string $startDate, string $endDate, bool $recurring = false): BudgetEntity
    {
        $budget = new BudgetEntity(
            id: null,
            endDate: $endDate,
            startDate: $startDate,
            amount: MoneyValueObject::fromCents(cents: $amount),
        );

        return $this->port->execute(operation: function () use ($budget, $recurring): BudgetEntity {
            if ($this->budgetRepository->hasOverlap(startDate: $budget->startDate, endDate: $budget->endDate)) {
                throw new OverlappingBudgetException;
            }

            if (! $recurring) {
                return $this->budgetRepository->save(budget: $budget);
            }

            $recurrence = $this->recurrenceRepository->save(
                recurrence: BudgetRecurrenceEntity::fromInitialBudget(budget: $budget),
            );

            return $this->budgetRepository->save(budget: new BudgetEntity(
                id: null,
                amount: $budget->amount,
                endDate: $budget->endDate,
                startDate: $budget->startDate,
                recurrenceId: $recurrence->id,
            ));
        });
    }
}
