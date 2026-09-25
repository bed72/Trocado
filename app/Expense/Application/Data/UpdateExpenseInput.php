<?php

declare(strict_types=1);

namespace App\Expense\Application\Data;

final readonly class UpdateExpenseInput
{
    public function __construct(
        public ?int $amount = null,
        public ?string $category = null,
        public ?string $occurredOn = null,
        public ?string $description = null,
        public bool $hasAmount = false,
        public bool $hasCategory = false,
        public bool $hasOccurredOn = false,
        public bool $hasDescription = false,
    ) {}
}
