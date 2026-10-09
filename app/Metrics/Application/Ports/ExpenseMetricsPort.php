<?php

declare(strict_types=1);

namespace App\Metrics\Application\Ports;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Metrics\Application\Data\ExpenseMetricsProjectionOutput;
use App\Metrics\Domain\Enums\ExpenseMetricsGroupingEnum;

interface ExpenseMetricsPort
{
    /**
     * Returns exact canonical cent strings for this owner and inclusive period.
     * Grouped totals must reconcile within one snapshot; total-only has no categories.
     */
    public function summarize(
        int $userId,
        DatePeriodValueObject $period,
        ExpenseMetricsGroupingEnum $grouping,
    ): ExpenseMetricsProjectionOutput;
}
