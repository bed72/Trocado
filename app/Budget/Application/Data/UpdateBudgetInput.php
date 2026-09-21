<?php

declare(strict_types=1);

namespace App\Budget\Application\Data;

final readonly class UpdateBudgetInput
{
    public function __construct(
        public int $id,
        public ?int $amount,
        public ?string $endDate,
        public ?string $startDate,
    ) {}
}
