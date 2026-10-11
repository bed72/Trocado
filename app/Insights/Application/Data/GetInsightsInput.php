<?php

declare(strict_types=1);

namespace App\Insights\Application\Data;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;

final readonly class GetInsightsInput
{
    public function __construct(
        public string $queryDate,
        public DatePeriodValueObject $selectedMonth,
    ) {}
}
