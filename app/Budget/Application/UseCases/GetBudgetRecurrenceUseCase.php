<?php

declare(strict_types=1);

namespace App\Budget\Application\UseCases;

use App\Budget\Application\Exceptions\BudgetRecurrenceNotFoundException;
use App\Budget\Application\Repositories\BudgetRecurrenceRepository;
use App\Budget\Domain\Entities\BudgetRecurrenceEntity;

final readonly class GetBudgetRecurrenceUseCase
{
    public function __construct(private BudgetRecurrenceRepository $repository) {}

    public function execute(int $id): BudgetRecurrenceEntity
    {
        return $this->repository->findById(id: $id) ?? throw new BudgetRecurrenceNotFoundException(id: $id);
    }
}
