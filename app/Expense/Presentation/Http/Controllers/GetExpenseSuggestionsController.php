<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Controllers;

use App\Core\Application\Ports\DatePort;
use App\Expense\Application\UseCases\GetExpenseSuggestionsUseCase;
use App\Expense\Presentation\Http\Requests\GetExpenseSuggestionsRequest;
use App\Expense\Presentation\Http\Responses\ExpenseSuggestionResponse;
use Illuminate\Http\JsonResponse;

final readonly class GetExpenseSuggestionsController
{
    public function __construct(private DatePort $port, private GetExpenseSuggestionsUseCase $useCase) {}

    public function __invoke(GetExpenseSuggestionsRequest $request): JsonResponse
    {
        return ExpenseSuggestionResponse::collection($this->useCase->execute(
            query: $request->searchTerm(), referenceDate: $this->port->today(),
        ))->response();
    }
}
