<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Controllers;

use App\Budget\Application\UseCases\GetAllBudgetsUseCase;
use App\Budget\Presentation\Http\Responses\BudgetResponse;
use Illuminate\Http\Resources\JsonApi\AnonymousResourceCollection;

final class GetAllBudgetsController
{
    public function __construct(private readonly GetAllBudgetsUseCase $useCase) {}

    public function __invoke(): AnonymousResourceCollection
    {
        return BudgetResponse::collection(resource: $this->useCase->execute());
    }
}
