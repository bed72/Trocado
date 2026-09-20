<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Controllers;

use App\Budget\Application\UseCases\UpdateBudgetUseCase;
use App\Budget\Presentation\Http\Requests\UpdateBudgetRequest;
use App\Budget\Presentation\Http\Responses\BudgetResponse;

final class UpdateBudgetController
{
    public function __construct(private readonly UpdateBudgetUseCase $useCase) {}

    public function __invoke(UpdateBudgetRequest $request, int $id): BudgetResponse
    {
        $attributes = $request->validated(key: 'data.attributes');

        return new BudgetResponse(resource: $this->useCase->execute(
            id: $id,
            endDate: $attributes['end_date'] ?? null,
            startDate: $attributes['start_date'] ?? null,
            amount: array_key_exists(key: 'amount', array: $attributes) ? (int) $attributes['amount'] : null,
        ));
    }
}
