<?php

declare(strict_types=1);

namespace App\Metrics\Presentation\Http\Controllers;

use App\Metrics\Application\UseCases\GetExpenseMetricsUseCase;
use App\Metrics\Presentation\Http\Requests\GetExpenseMetricsRequest;
use App\Metrics\Presentation\Http\Responses\ExpenseMetricsResponse;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Config;

final readonly class GetExpenseMetricsController
{
    public function __construct(private GetExpenseMetricsUseCase $useCase) {}

    public function __invoke(GetExpenseMetricsRequest $request): ExpenseMetricsResponse
    {
        $date = Carbon::now(Config::get('app.timezone'))->format('Y-m-d');

        return new ExpenseMetricsResponse($this->useCase->execute($request->toInput($date)));
    }
}
