<?php

declare(strict_types=1);

namespace App\Budget\Application\UseCases;

use App\Budget\Application\Data\UpdateBudgetInput;
use App\Budget\Application\Ports\BudgetWritePort;
use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\Exceptions\OverlappingBudgetException;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

final readonly class UpdateBudgetUseCase
{
    public function __construct(
        private BudgetWritePort $port,
        private GetBudgetUseCase $useCase,
        private BudgetRepository $repository,
    ) {}

    public function execute(UpdateBudgetInput $input): BudgetEntity
    {
        return $this->port->execute(operation: function () use ($input): BudgetEntity {
            $current = $this->useCase->execute(id: $input->id);
            $updated = new BudgetEntity(
                id: $input->id,
                createdAt: $current->createdAt,
                updatedAt: $current->updatedAt,
                recurrenceId: $current->recurrenceId,
                endDate: $input->endDate ?? $current->endDate,
                startDate: $input->startDate ?? $current->startDate,
                amount: $input->amount === null ? $current->amount : MoneyValueObject::fromCents(cents: $input->amount),
            );

            if ($this->repository->hasOverlap(
                excludeId: $input->id,
                endDate: $updated->endDate,
                startDate: $updated->startDate,
            )) {
                throw new OverlappingBudgetException;
            }

            return $this->repository->create(budget: $updated);
        });
    }
}
