<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Controllers;

use App\Expense\Application\UseCases\GetExpenseUseCase;
use App\Expense\Presentation\Http\Responses\ExpenseResponse;

final readonly class GetExpenseController
{
    public function __construct(private GetExpenseUseCase $useCase) {}

    public function __invoke(int $expense): ExpenseResponse
    {
        return new ExpenseResponse(resource: $this->useCase->execute(id: $expense));
    }
}
