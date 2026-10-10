<?php

declare(strict_types=1);

namespace App\Metrics\Application\Data;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;

final readonly class ExpenseMetricsOutput
{
    /** @param list<ExpenseCategoryMetricsOutput>|null $categories */
    public function __construct(
        public string $id,
        public ?array $categories,
        public string $totalAmount,
        public DatePeriodValueObject $period,
    ) {}
}
