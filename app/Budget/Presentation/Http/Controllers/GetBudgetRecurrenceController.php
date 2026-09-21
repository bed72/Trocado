<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Controllers;

use App\Budget\Application\UseCases\GetBudgetRecurrenceUseCase;
use App\Budget\Presentation\Http\Responses\BudgetRecurrenceResponse;

final class GetBudgetRecurrenceController
{
    public function __construct(private readonly GetBudgetRecurrenceUseCase $useCase) {}

    public function __invoke(int $id): BudgetRecurrenceResponse
    {
        return new BudgetRecurrenceResponse(resource: $this->useCase->execute(id: $id));
    }
}
