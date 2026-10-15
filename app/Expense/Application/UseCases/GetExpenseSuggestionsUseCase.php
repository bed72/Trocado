<?php

declare(strict_types=1);

namespace App\Expense\Application\UseCases;

use App\Core\Application\Data\ResourceInput;
use App\Core\Application\Data\ResourceKeyInput;
use App\Core\Application\Ports\UserPort;
use App\Core\Application\UseCases\ResourceUseCase;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Core\Domain\ValueObjects\UuidValueObject;
use App\Expense\Application\Data\ExpenseSuggestionHistoryOutput;
use App\Expense\Application\Data\ExpenseSuggestionOutput;
use App\Expense\Application\Exceptions\InvalidExpenseSuggestionsProjectionException;
use App\Expense\Application\Repositories\ExpenseSuggestionsRepository;
use DateTimeImmutable;
use DateTimeZone;

use function count;
use function in_array;

final readonly class GetExpenseSuggestionsUseCase
{
    public function __construct(
        private UserPort $port,
        private ResourceUseCase $useCase,
        private ExpenseSuggestionsRepository $repository,
    ) {}

    /** @return list<ExpenseSuggestionOutput> */
    public function execute(string $query, string $referenceDate): array
    {
        $keys = [];
        $prepared = [];
        $month = DatePeriodValueObject::monthContaining($referenceDate);
        $userId = UuidValueObject::fromString($this->port->id())->value();
        $monthStart = new DateTimeImmutable($month->from(), new DateTimeZone('UTC'));
        $period = DatePeriodValueObject::fromDates(
            to: $monthStart->modify('-1 day')->format('Y-m-d'),
            from: $monthStart->modify('-3 months')->format('Y-m-d'),
        );
        $history = $this->repository->search(userId: $userId, query: $query, period: $period);

        if (! array_is_list($history) || count($history) > 5) {
            throw new InvalidExpenseSuggestionsProjectionException;
        }

        foreach ($history as $projection) {
            if (! $projection instanceof ExpenseSuggestionHistoryOutput
                || $projection->key === '' || $projection->description === ''
                || in_array($projection->key, $keys, true)) {
                throw new InvalidExpenseSuggestionsProjectionException;
            }

            $keys[] = $projection->key;
            $prepared[] = [
                'description' => $projection->description,
                'amount' => $projection->representedMonths === 3
                    && $projection->minimumAmount !== null
                    && $projection->minimumAmount > 0
                    && $projection->minimumAmount === $projection->maximumAmount
                        ? $projection->minimumAmount
                        : null,
            ];
        }

        if ($prepared === []) {
            return [];
        }

        $resources = $this->useCase->execute(new ResourceInput(
            userId: $userId,
            identities: array_map(static fn (string $key): ResourceKeyInput => new ResourceKeyInput(
                identityVersion: 1,
                namespace: 'expense-suggestions',
                components: ['description_key' => $key],
            ), $keys),
        ));
        $suggestions = [];

        foreach ($prepared as $index => $suggestion) {
            $suggestions[] = new ExpenseSuggestionOutput(
                id: $resources->identities[$index]->id,
                amount: $suggestion['amount'],
                description: $suggestion['description'],
            );
        }

        return $suggestions;
    }
}
