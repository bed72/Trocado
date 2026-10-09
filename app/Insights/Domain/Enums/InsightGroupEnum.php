<?php

declare(strict_types=1);

namespace App\Insights\Domain\Enums;

enum InsightGroupEnum: string
{
    case Comparison = 'comparison';
    case Onboarding = 'onboarding';
    case Observation = 'observation';
}
