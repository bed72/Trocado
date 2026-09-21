<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Controllers;

use App\Budget\Application\Data\CreateBudgetInput;
use App\Budget\Application\UseCases\CreateBudgetUseCase;
use App\Budget\Presentation\Http\Requests\CreateBudgetRequest;
use App\Budget\Presentation\Http\Responses\BudgetResponse;
use Illuminate\Http\JsonResponse;
use Symfony\Component\HttpFoundation\Response;

final class CreateBudgetController
{
    public function __construct(private readonly CreateBudgetUseCase $useCase) {}

    public function __invoke(CreateBudgetRequest $request): JsonResponse
    {
        $attributes = $request->validated(key: 'data.attributes');
        $budget = $this->useCase->execute(input: new CreateBudgetInput(
            endDate: $attributes['end_date'],
            amount: (int) $attributes['amount'],
            startDate: $attributes['start_date'],
            recurring: $attributes['recurring'] ?? false,
        ));

        return (new BudgetResponse(resource: $budget))->response()
            ->setStatusCode(code: Response::HTTP_CREATED)
            ->header(key: 'Location', values: route(name: 'budgets.get', parameters: ['budget' => $budget->id]));
    }
}
