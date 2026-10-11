<?php

declare(strict_types=1);

namespace App\Expense\Application\Data;

final readonly class ExpenseSuggestionOutput
{
    public function __construct(
        public string $id,
        public string $description,
        public ?int $amount,
    ) {}
}
