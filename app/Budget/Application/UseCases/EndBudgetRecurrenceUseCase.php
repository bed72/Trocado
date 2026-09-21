<?php

declare(strict_types=1);

namespace App\Budget\Application\UseCases;

use App\Budget\Application\Exceptions\BudgetRecurrenceNotFoundException;
use App\Budget\Application\Ports\BudgetWritePort;
use App\Budget\Application\Repositories\BudgetRecurrenceRepository;
use App\Budget\Domain\Entities\BudgetRecurrenceEntity;
use DateTimeImmutable;

final readonly class EndBudgetRecurrenceUseCase
{
    public function __construct(
        private BudgetWritePort $port,
        private BudgetRecurrenceRepository $repository,
    ) {}

    public function execute(int $id, DateTimeImmutable $endedAt): BudgetRecurrenceEntity
    {
        return $this->port->execute(operation: function () use ($id, $endedAt): BudgetRecurrenceEntity {
            $recurrence = $this->repository->findByIdForUpdate(id: $id)
                ?? throw new BudgetRecurrenceNotFoundException(id: $id);

            return $this->repository->create(recurrence: $recurrence->end(endedAt: $endedAt));
        });
    }
}
