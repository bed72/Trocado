<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Controllers;

use App\Budget\Application\UseCases\EndBudgetRecurrenceUseCase;
use App\Budget\Presentation\Http\Responses\BudgetRecurrenceResponse;
use Illuminate\Support\Facades\Date;

final class EndBudgetRecurrenceController
{
    public function __construct(private readonly EndBudgetRecurrenceUseCase $useCase) {}

    public function __invoke(int $id): BudgetRecurrenceResponse
    {
        return new BudgetRecurrenceResponse(resource: $this->useCase->execute(
            id: $id,
            endedAt: Date::now()->toDateTimeImmutable(),
        ));
    }
}
