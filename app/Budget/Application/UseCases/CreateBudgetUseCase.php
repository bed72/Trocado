<?php

declare(strict_types=1);

namespace App\Budget\Application\UseCases;

use App\Budget\Application\Data\CreateBudgetInput;
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

    public function execute(CreateBudgetInput $input): BudgetEntity
    {
        $budget = new BudgetEntity(
            id: null,
            endDate: $input->endDate,
            startDate: $input->startDate,
            amount: MoneyValueObject::fromCents(cents: $input->amount),
        );

        return $this->port->execute(operation: function () use ($budget, $input): BudgetEntity {
            if ($this->budgetRepository->hasOverlap(startDate: $budget->startDate, endDate: $budget->endDate)) {
                throw new OverlappingBudgetException;
            }

            if (! $input->recurring) {
                return $this->budgetRepository->create(budget: $budget);
            }

            $recurrence = $this->recurrenceRepository->create(
                recurrence: BudgetRecurrenceEntity::fromInitialBudget(budget: $budget),
            );

            return $this->budgetRepository->create(budget: new BudgetEntity(
                id: null,
                amount: $budget->amount,
                endDate: $budget->endDate,
                startDate: $budget->startDate,
                recurrenceId: $recurrence->id,
            ));
        });
    }
}
