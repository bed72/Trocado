<?php

declare(strict_types=1);

namespace App\Expense\Application\Data;

final readonly class ExpenseSuggestionHistoryOutput
{
    public function __construct(
        public string $key,
        public string $description,
        public int $representedMonths,
        public ?int $minimumAmount,
        public ?int $maximumAmount,
    ) {}
}
