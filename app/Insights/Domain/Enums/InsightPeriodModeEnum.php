<?php

declare(strict_types=1);

namespace App\Insights\Domain\Enums;

enum InsightPeriodModeEnum: string
{
    case Closed = 'closed';
    case Current = 'current';
}
