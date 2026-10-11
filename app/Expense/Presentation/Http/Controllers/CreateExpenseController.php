<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Controllers;

use App\Core\Application\Ports\DatePort;
use App\Expense\Application\Data\CreateExpenseInput;
use App\Expense\Application\UseCases\CreateExpenseUseCase;
use App\Expense\Presentation\Http\Requests\CreateExpenseRequest;
use App\Expense\Presentation\Http\Responses\ExpenseResponse;
use Illuminate\Http\JsonResponse;
use Symfony\Component\HttpFoundation\Response;

final class CreateExpenseController
{
    public function __construct(private readonly DatePort $port, private readonly CreateExpenseUseCase $useCase) {}

    public function __invoke(CreateExpenseRequest $request): JsonResponse
    {
        $attributes = $request->validated(key: 'data.attributes');
        $expense = $this->useCase->execute(input: new CreateExpenseInput(
            amount: $attributes['amount'],
            category: $attributes['category'] ?? null,
            description: $attributes['description'] ?? null,
            occurredOn: $attributes['occurred_on'] ?? $this->port->today(),
        ));

        return (new ExpenseResponse(resource: $expense))->response()
            ->setStatusCode(code: Response::HTTP_CREATED);
    }
}
