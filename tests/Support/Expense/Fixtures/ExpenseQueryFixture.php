<?php

declare(strict_types=1);

namespace Tests\Support\Expense\Fixtures;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Expense\Application\Data\GetAllExpenseInput;
use Illuminate\Pagination\Cursor;

final class ExpenseQueryFixture
{
    public static function input(int $size = 20, ?string $cursor = null, ?DatePeriodValueObject $period = null): GetAllExpenseInput
    {
        return new GetAllExpenseInput(size: $size, cursor: $cursor, from: $period?->from(), to: $period?->to(), legacyCursorAllowed: true);
    }

    public static function legacyCursor(): string
    {
        return (new Cursor(['occurred_on' => '2026-09-24', 'id' => 5], true))->encode();
    }
}
