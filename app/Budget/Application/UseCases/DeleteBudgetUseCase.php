<?php

declare(strict_types=1);

namespace App\Budget\Application\UseCases;

use App\Budget\Application\Exceptions\BudgetNotFoundException;
use App\Budget\Application\Repositories\BudgetRepository;

final readonly class DeleteBudgetUseCase
{
    public function __construct(private BudgetRepository $repository) {}

    public function execute(int $id): void
    {
        if (! $this->repository->delete(id: $id)) {
            throw new BudgetNotFoundException;
        }
    }
}
