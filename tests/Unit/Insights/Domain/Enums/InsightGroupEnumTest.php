<?php

declare(strict_types=1);

use App\Insights\Domain\Enums\InsightGroupEnum;

it('exposes the three groups defined by the insights contract', function (): void {
    expect(array_map(
        array: InsightGroupEnum::cases(),
        callback: static fn (InsightGroupEnum $group): string => $group->value,
    ))->toEqualCanonicalizing(['observation', 'comparison', 'onboarding']);
});
