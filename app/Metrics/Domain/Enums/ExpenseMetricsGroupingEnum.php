<?php

declare(strict_types=1);

namespace App\Metrics\Domain\Enums;

enum ExpenseMetricsGroupingEnum: string
{
    case Total = 'total';
    case Category = 'category';
}
