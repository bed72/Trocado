<?php

declare(strict_types=1);

namespace App\Metrics\Presentation\Http\Controllers;

use App\Core\Application\Ports\DatePort;
use App\Metrics\Application\UseCases\GetExpenseMetricsUseCase;
use App\Metrics\Presentation\Http\Requests\GetExpenseMetricsRequest;
use App\Metrics\Presentation\Http\Responses\ExpenseMetricsResponse;

final readonly class GetExpenseMetricsController
{
    public function __construct(private DatePort $port, private GetExpenseMetricsUseCase $useCase) {}

    public function __invoke(GetExpenseMetricsRequest $request): ExpenseMetricsResponse
    {
        return new ExpenseMetricsResponse($this->useCase->execute($request->toInput($this->port->today())));
    }
}
