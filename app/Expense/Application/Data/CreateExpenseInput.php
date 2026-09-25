<?php

declare(strict_types=1);

namespace App\Expense\Application\Data;

final readonly class CreateExpenseInput
{
    public function __construct(
        public int $amount,
        public string $occurredOn,
        public ?string $category = null,
        public ?string $description = null,
    ) {}
}
