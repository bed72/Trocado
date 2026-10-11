<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Core\Application\Ports\UserPort;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Expense\Application\Data\ExpenseSuggestionOutput;
use App\Expense\Application\Repositories\ExpenseSuggestionsRepository;
use DateTimeImmutable;
use DateTimeZone;

final readonly class GetExpenseSuggestionsUseCase
{
    public function __construct(private UserPort $port, private ExpenseSuggestionsRepository $repository) {}

    /** @return list<ExpenseSuggestionOutput> */
    public function execute(string $query, string $referenceDate): array
    {
        $userId = $this->port->id();
        $month = DatePeriodValueObject::monthContaining($referenceDate);
        $monthStart = new DateTimeImmutable($month->from(), new DateTimeZone('UTC'));
        $period = DatePeriodValueObject::fromDates(
            to: $monthStart->modify('-1 day')->format('Y-m-d'),
            from: $monthStart->modify('-3 months')->format('Y-m-d'),
        );
        $history = $this->repository->search(userId: $userId, query: $query, period: $period);
        $suggestions = [];

        foreach ($history as $projection) {
            $suggestions[] = new ExpenseSuggestionOutput(
                id: hash('sha256', "expense-suggestion:v1:{$userId}:".strlen($projection->key).':'.$projection->key),
                description: $projection->description,
                amount: $projection->representedMonths === 3
                    && $projection->minimumAmount !== null
                    && $projection->minimumAmount > 0
                    && $projection->minimumAmount === $projection->maximumAmount
                        ? $projection->minimumAmount
                        : null,
            );
        }

        return $suggestions;
    }
}
