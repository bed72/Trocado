<?php

declare(strict_types=1);

namespace App\Budget\Application\UseCases;

use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

final readonly class CreateBudgetUseCase
{
    public function __construct(private BudgetRepository $repository) {}

    public function execute(int $amount, string $startDate, string $endDate): BudgetEntity
    {
        return $this->repository->save(budget: new BudgetEntity(
            id: null,
            endDate: $endDate,
            startDate: $startDate,
            amount: MoneyValueObject::fromCents(cents: $amount),
        ));
    }
}
