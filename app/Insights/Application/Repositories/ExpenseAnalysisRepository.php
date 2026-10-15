<?php

declare(strict_types=1);

namespace App\Insights\Application\Repositories;

use App\Insights\Application\Data\ExpenseAnalysisOutput;
use App\Insights\Domain\ValueObjects\InsightAnalysisPeriodValueObject;

interface ExpenseAnalysisRepository
{
    public function analyze(string $userId, InsightAnalysisPeriodValueObject $period): ExpenseAnalysisOutput;
}
