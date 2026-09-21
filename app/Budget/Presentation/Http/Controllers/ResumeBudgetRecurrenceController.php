<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Controllers;

use App\Budget\Application\UseCases\ResumeBudgetRecurrenceUseCase;
use App\Budget\Presentation\Http\Responses\BudgetRecurrenceResponse;

final class ResumeBudgetRecurrenceController
{
    public function __construct(private readonly ResumeBudgetRecurrenceUseCase $useCase) {}

    public function __invoke(int $id): BudgetRecurrenceResponse
    {
        return new BudgetRecurrenceResponse(resource: $this->useCase->execute(id: $id));
    }
}
