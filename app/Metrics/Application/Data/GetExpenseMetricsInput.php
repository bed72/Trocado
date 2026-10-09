<?php

declare(strict_types=1);

namespace App\Metrics\Application\Data;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Metrics\Domain\Enums\ExpenseMetricsGroupingEnum;

final readonly class GetExpenseMetricsInput
{
    public function __construct(
        public DatePeriodValueObject $period,
        public ExpenseMetricsGroupingEnum $grouping = ExpenseMetricsGroupingEnum::Total,
    ) {}
}
