<?php

declare(strict_types=1);

namespace App\Insights\Application\Data;

final readonly class SelectInsightMessageVariantInput
{
    public function __construct(
        public int $userId,
        public int $variantCount,
        public string $editorialKey,
        public string $referenceDate,
    ) {}
}
