<?php

declare(strict_types=1);

namespace App\Budget\Application\UseCases;

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

    public function execute(int $id, ?int $amount, ?string $startDate, ?string $endDate): BudgetEntity
    {
        return $this->port->execute(operation: function () use ($id, $amount, $startDate, $endDate): BudgetEntity {
            $current = $this->useCase->execute(id: $id);
            $updated = new BudgetEntity(
                id: $id,
                createdAt: $current->createdAt,
                updatedAt: $current->updatedAt,
                endDate: $endDate ?? $current->endDate,
                startDate: $startDate ?? $current->startDate,
                amount: $amount === null ? $current->amount : MoneyValueObject::fromCents(cents: $amount),
                recurrenceId: $current->recurrenceId,
            );

            if ($this->repository->hasOverlap(
                excludeId: $id,
                endDate: $updated->endDate,
                startDate: $updated->startDate,
            )) {
                throw new OverlappingBudgetException;
            }

            return $this->repository->save(budget: $updated);
        });
    }
}
