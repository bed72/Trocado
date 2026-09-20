<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Controllers;

use App\Budget\Application\UseCases\GetBudgetUseCase;
use App\Budget\Presentation\Http\Resources\BudgetResponse;

final class GetBudgetController
{
    public function __construct(private readonly GetBudgetUseCase $useCase) {}

    public function __invoke(int $id): BudgetResponse
    {
        return new BudgetResponse(resource: $this->useCase->execute(id: $id));
    }
}
