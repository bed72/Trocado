<?php

declare(strict_types=1);

namespace App\Expense\Application\Repositories;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Expense\Application\Data\ExpenseSuggestionHistoryOutput;

interface ExpenseSuggestionsRepository
{
    /** @return list<ExpenseSuggestionHistoryOutput> Up to five ranked groups with all monetary facts from the inclusive period. */
    public function search(int $userId, string $query, DatePeriodValueObject $period): array;
}
