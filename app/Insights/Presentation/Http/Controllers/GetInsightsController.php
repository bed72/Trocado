<?php

declare(strict_types=1);

namespace App\Insights\Presentation\Http\Controllers;

use App\Insights\Application\UseCases\GetInsightsUseCase;
use App\Insights\Presentation\Http\Requests\GetInsightsRequest;
use App\Insights\Presentation\Http\Responses\InsightResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Date;

final readonly class GetInsightsController
{
    public function __construct(private GetInsightsUseCase $useCase) {}

    public function __invoke(GetInsightsRequest $request): JsonResponse
    {
        $referenceDate = Date::now(Config::string('app.timezone'))->toDateString();

        return InsightResponse::collection($this->useCase->execute(referenceDate: $referenceDate))->response($request);
    }
}
