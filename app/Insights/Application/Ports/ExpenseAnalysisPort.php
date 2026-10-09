<?php

declare(strict_types=1);

namespace App\Insights\Application\Ports;

use App\Insights\Application\Data\ExpenseAnalysisOutput;

interface ExpenseAnalysisPort
{
    public function analyze(int $userId, string $referenceDate): ExpenseAnalysisOutput;
}
