<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Controllers;

use App\Expense\Application\UseCases\ListOwnedExpensesUseCase;
use App\Expense\Presentation\Http\Requests\ListOwnedExpensesRequest;
use App\Expense\Presentation\Http\Responses\ExpenseResponse;
use Illuminate\Http\JsonResponse;

final readonly class ListOwnedExpensesController
{
    public function __construct(private ListOwnedExpensesUseCase $useCase) {}

    public function __invoke(ListOwnedExpensesRequest $request): JsonResponse
    {
        $page = $this->useCase->execute(
            cursor: $request->validated('page.cursor'),
            size: (int) $request->validated('page.size', 20),
            userId: (int) $request->user()->getAuthIdentifier(),
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
