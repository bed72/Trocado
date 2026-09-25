<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Controllers;

use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Application\UseCases\UpdateExpenseUseCase;
use App\Expense\Presentation\Http\Requests\UpdateExpenseRequest;
use App\Expense\Presentation\Http\Responses\ExpenseResponse;
use Illuminate\Http\JsonResponse;

use function array_key_exists;

final readonly class UpdateExpenseController
{
    public function __construct(private UpdateExpenseUseCase $useCase) {}

    public function __invoke(UpdateExpenseRequest $request, int $expense): JsonResponse
    {
        $attributes = $request->validated(key: 'data.attributes');

        return (new ExpenseResponse(resource: $this->useCase->execute(
            id: $expense,
            input: new UpdateExpenseInput(
                amount: $attributes['amount'] ?? null,
                category: $attributes['category'] ?? null,
                occurredOn: $attributes['occurred_on'] ?? null,
                description: $attributes['description'] ?? null,
                hasAmount: array_key_exists('amount', $attributes),
                hasCategory: array_key_exists('category', $attributes),
                hasOccurredOn: array_key_exists('occurred_on', $attributes),
                hasDescription: array_key_exists('description', $attributes),
            ),
        )))->response();
    }
}
