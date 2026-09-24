<?php

declare(strict_types=1);

namespace App\Expense\Application\Data;

use App\Expense\Domain\Entities\ExpenseEntity;

final readonly class ExpensePageOutput
{
    /** @param list<ExpenseEntity> $items */
    public function __construct(
        public array $items,
        public ?string $nextCursor,
        public ?string $previousCursor,
    ) {}
}
