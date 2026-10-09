<?php

declare(strict_types=1);

namespace App\Insights\Domain\Enums;

enum InsightHistoryStateEnum: string
{
    case CurrentExpenses = 'current_expenses';
    case NoCurrentExpenses = 'no_current_expenses';
}
