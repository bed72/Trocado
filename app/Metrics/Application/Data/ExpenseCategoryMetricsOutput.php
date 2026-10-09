<?php

declare(strict_types=1);

namespace App\Metrics\Application\Data;

final readonly class ExpenseCategoryMetricsOutput
{
    public function __construct(
        public string $category,
        public string $percentage,
        public string $totalCents,
    ) {}
}
