<?php

declare(strict_types=1);

namespace App\Insights\Application\Data;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Domain\Enums\InsightGroupEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;

final readonly class InsightOutput
{
    public function __construct(
        public string $id,
        public string $title,
        public string $description,
        public InsightTypeEnum $type,
        public InsightGroupEnum $group,
        public ?DatePeriodValueObject $period,
        public ?DatePeriodValueObject $comparisonPeriod,
    ) {}
}
