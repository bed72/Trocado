<?php

declare(strict_types=1);

namespace App\Budget\Application\UseCases;

use App\Budget\Application\Exceptions\BudgetRecurrenceNotFoundException;
use App\Budget\Application\Ports\BudgetWritePort;
use App\Budget\Application\Repositories\BudgetRecurrenceRepository;
use App\Budget\Domain\Entities\BudgetRecurrenceEntity;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

final readonly class UpdateBudgetRecurrenceUseCase
{
    public function __construct(
        private BudgetWritePort $port,
        private BudgetRecurrenceRepository $repository,
    ) {}

    public function execute(int $id, ?int $amount, ?int $durationInDays): BudgetRecurrenceEntity
    {
        return $this->port->execute(operation: function () use ($id, $amount, $durationInDays): BudgetRecurrenceEntity {
            $recurrence = $this->repository->findByIdForUpdate(id: $id)
                ?? throw new BudgetRecurrenceNotFoundException(id: $id);

            return $this->repository->create(recurrence: $recurrence->updateTemplate(
                durationInDays: $durationInDays,
                amount: $amount === null ? null : MoneyValueObject::fromCents(cents: $amount),
            ));
        });
    }
}
