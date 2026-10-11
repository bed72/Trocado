<?php

declare(strict_types=1);

namespace App\Insights\Presentation\Http\Controllers;

use App\Core\Application\Ports\DatePort;
use App\Insights\Application\UseCases\GetInsightsUseCase;
use App\Insights\Presentation\Http\Requests\GetInsightsRequest;
use App\Insights\Presentation\Http\Responses\InsightResponse;
use Illuminate\Http\JsonResponse;

final readonly class GetInsightsController
{
    public function __construct(private DatePort $port, private GetInsightsUseCase $useCase) {}

    public function __invoke(GetInsightsRequest $request): JsonResponse
    {
        return InsightResponse::collection($this->useCase->execute(referenceDate: $this->port->today()))->response($request);
    }
}
