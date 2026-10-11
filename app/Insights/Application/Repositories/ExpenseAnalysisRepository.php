<?php

declare(strict_types=1);

namespace App\Insights\Application\Repositories;

use App\Insights\Application\Data\ExpenseAnalysisOutput;

interface ExpenseAnalysisRepository
{
    public function analyze(int $userId, string $referenceDate): ExpenseAnalysisOutput;
}
