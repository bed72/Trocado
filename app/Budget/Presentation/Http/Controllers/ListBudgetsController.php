<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Controllers;

use App\Budget\Application\UseCases\ListBudgetsUseCase;
use App\Budget\Presentation\Http\Resources\BudgetResponse;
use Illuminate\Http\Resources\JsonApi\AnonymousResourceCollection;

final class ListBudgetsController
{
    public function __construct(private readonly ListBudgetsUseCase $useCase) {}

    public function __invoke(): AnonymousResourceCollection
    {
        return BudgetResponse::collection(resource: $this->useCase->execute());
    }
}
