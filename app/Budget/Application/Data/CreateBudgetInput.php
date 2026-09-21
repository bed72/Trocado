<?php

declare(strict_types=1);

namespace App\Budget\Application\Data;

final readonly class CreateBudgetInput
{
    public function __construct(
        public int $amount,
        public string $endDate,
        public string $startDate,
        public bool $recurring = false,
    ) {}
}
