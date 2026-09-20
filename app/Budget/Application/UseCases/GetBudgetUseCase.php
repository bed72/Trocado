<?php

declare(strict_types=1);

namespace App\Budget\Application\UseCases;

use App\Budget\Application\Exceptions\BudgetNotFoundException;
use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Domain\Entities\BudgetEntity;

final readonly class GetBudgetUseCase
{
    public function __construct(private BudgetRepository $repository) {}

    public function execute(int $id): BudgetEntity
    {
        return $this->repository->findById(id: $id) ?? throw new BudgetNotFoundException(id: $id);
    }
}
