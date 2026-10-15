<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Repositories\Persistence;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Expense\Application\Data\ExpenseSuggestionHistoryOutput;
use App\Expense\Application\Repositories\ExpenseSuggestionsRepository;
use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use Illuminate\Database\Eloquent\Builder;
use stdClass;

final class EloquentExpenseSuggestionsRepository implements ExpenseSuggestionsRepository
{
    public function search(string $userId, string $query, DatePeriodValueObject $period): array
    {
        $owned = $this->ownedDescriptionsQuery($userId);
        $rows = $owned->getModel()->getConnection()->select(
            $this->suggestionsSql($owned->toSql()),
            [...$owned->getBindings(), $query, $period->from(), $period->to()],
        );

        return $this->mapHistory($rows);
    }

    /** @return Builder<ExpenseModel> */
    private function ownedDescriptionsQuery(string $userId): Builder
    {
        return ExpenseModel::query()
            ->where('user_id', $userId)
            ->whereNotNull('description')
            ->select('id', 'amount', 'occurred_on', 'created_at')
            ->selectRaw("regexp_replace(description, '^[[:space:]]+|[[:space:]]+$', '', 'g') AS description");
    }

    private function suggestionsSql(string $ownedSql): string
    {
        return <<<SQL
            WITH normalized AS ({$ownedSql}),
            keyed AS (
                SELECT *, lower(description) COLLATE "C" AS key
                FROM normalized
                WHERE description <> ''
            ),
            parameters AS (
                SELECT lower(regexp_replace(CAST(? AS text), '^[[:space:]]+|[[:space:]]+$', '', 'g')) AS term,
                    CAST(? AS date) AS from_date, CAST(? AS date) AS to_date
            ),
            matched AS (
                SELECT keyed.*, strpos(key, term) = 1 AS is_prefix,
                    occurred_on BETWEEN from_date AND to_date AS in_window,
                    row_number() OVER (PARTITION BY key ORDER BY created_at DESC, id DESC) AS spelling_rank
                FROM keyed CROSS JOIN parameters
                WHERE strpos(key, term) > 0
            )
            SELECT key,
                max(description) FILTER (WHERE spelling_rank = 1) AS description,
                count(DISTINCT date_trunc('month', occurred_on)) FILTER (WHERE in_window) AS represented_months,
                min(amount) FILTER (WHERE in_window) AS minimum_amount,
                max(amount) FILTER (WHERE in_window) AS maximum_amount
            FROM matched
            GROUP BY key, is_prefix
            ORDER BY is_prefix DESC, max(created_at) DESC, count(*) DESC, key COLLATE "C" ASC
            LIMIT 5
            SQL;
    }

    /**
     * @param  list<stdClass>  $rows
     * @return list<ExpenseSuggestionHistoryOutput>
     */
    private function mapHistory(array $rows): array
    {
        $history = [];

        foreach ($rows as $row) {
            $history[] = new ExpenseSuggestionHistoryOutput(
                key: $row->key,
                description: $row->description,
                representedMonths: (int) $row->represented_months,
                minimumAmount: $row->minimum_amount === null ? null : (int) $row->minimum_amount,
                maximumAmount: $row->maximum_amount === null ? null : (int) $row->maximum_amount,
            );
        }

        return $history;
    }
}
