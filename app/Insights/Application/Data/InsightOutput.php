<?php

declare(strict_types=1);

namespace App\Insights\Application\Data;

use App\Insights\Domain\Enums\InsightGroupEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\ValueObjects\InsightPeriodValueObject;

final readonly class InsightOutput
{
    public function __construct(
        public string $id,
        public string $title,
        public string $description,
        public InsightTypeEnum $type,
        public InsightGroupEnum $group,
        public ?InsightPeriodValueObject $period,
        public ?InsightPeriodValueObject $comparisonPeriod,
    ) {}
}
