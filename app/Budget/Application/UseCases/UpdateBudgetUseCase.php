<?php

declare(strict_types=1);

namespace App\Budget\Application\UseCases;

use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

final readonly class UpdateBudgetUseCase
{
    public function __construct(private GetBudgetUseCase $useCase, private BudgetRepository $repository) {}

    public function execute(int $id, ?int $amount, ?string $startDate, ?string $endDate): BudgetEntity
    {
        $current = $this->useCase->execute(id: $id);

        return $this->repository->save(budget: new BudgetEntity(
            id: $id,
            createdAt: $current->createdAt,
            updatedAt: $current->updatedAt,
            endDate: $endDate ?? $current->endDate,
            startDate: $startDate ?? $current->startDate,
            amount: $amount === null ? $current->amount : MoneyValueObject::fromCents(cents: $amount),
        ));
    }
}
