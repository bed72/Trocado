<?php

declare(strict_types=1);

namespace App\Expense\Application\Data;

final readonly class ExpenseCursorOutput
{
    /** @param array<string, int|string> $position */
    public function __construct(public array $position, public bool $forward) {}
}
