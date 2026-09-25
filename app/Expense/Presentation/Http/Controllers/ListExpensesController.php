<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Controllers;

use App\Expense\Application\UseCases\ListExpensesUseCase;
use App\Expense\Presentation\Http\Requests\ListExpensesRequest;
use App\Expense\Presentation\Http\Responses\ExpenseResponse;
use Illuminate\Http\JsonResponse;

final readonly class ListExpensesController
{
    public function __construct(private ListExpensesUseCase $useCase) {}

    public function __invoke(ListExpensesRequest $request): JsonResponse
    {
        $page = $this->useCase->execute(
            cursor: $request->validated('page.cursor'),
            size: (int) $request->validated('page.size', 20),
        );

        $link = static fn (?string $cursor): ?string => $cursor === null ? null : route('expenses.index', [
            'page' => ['size' => (int) $request->validated('page.size', 20), 'cursor' => $cursor],
        ]);

        return ExpenseResponse::collection($page->items)
            ->additional(['links' => [
                'next' => $link($page->nextCursor),
                'prev' => $link($page->previousCursor),
            ]])
            ->response();
    }
}
