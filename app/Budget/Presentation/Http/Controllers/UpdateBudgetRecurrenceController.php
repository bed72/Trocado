<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Controllers;

use App\Budget\Application\UseCases\UpdateBudgetRecurrenceUseCase;
use App\Budget\Presentation\Http\Requests\UpdateBudgetRecurrenceRequest;
use App\Budget\Presentation\Http\Responses\BudgetRecurrenceResponse;

final class UpdateBudgetRecurrenceController
{
    public function __construct(private readonly UpdateBudgetRecurrenceUseCase $useCase) {}

    public function __invoke(UpdateBudgetRecurrenceRequest $request, int $id): BudgetRecurrenceResponse
    {
        $attributes = $request->validated(key: 'data.attributes');

        return new BudgetRecurrenceResponse(resource: $this->useCase->execute(
            id: $id,
            amount: array_key_exists(key: 'amount', array: $attributes) ? (int) $attributes['amount'] : null,
            durationInDays: array_key_exists(key: 'duration_in_days', array: $attributes)
                ? (int) $attributes['duration_in_days']
                : null,
        ));
    }
}
