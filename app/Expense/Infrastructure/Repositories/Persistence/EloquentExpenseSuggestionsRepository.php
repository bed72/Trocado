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
            ->select('id', 'amount', 'occurred_on', 'created_at', 'description');
    }

    private function suggestionsSql(string $ownedSql): string
    {
        return <<<SQL
            WITH normalized AS MATERIALIZED (
                SELECT owned.id, owned.amount, owned.occurred_on, owned.created_at,
                    regexp_replace(owned.description, '^[[:space:]]+|[[:space:]]+$', '', 'g') AS description,
                    search.term
                FROM ({$ownedSql}) owned
                CROSS JOIN (
                    SELECT lower(regexp_replace(CAST(? AS text), '^[[:space:]]+|[[:space:]]+$', '', 'g')) AS term
                ) search
                WHERE strpos(lower(owned.description) COLLATE "C", term) > 0
            ),
            parameters AS (
                SELECT CAST(? AS date) AS from_date, CAST(? AS date) AS to_date
            ),
            ranked_groups AS MATERIALIZED (
                SELECT lower(description) COLLATE "C" AS key,
                    strpos(lower(description) COLLATE "C", term) = 1 AS is_prefix,
                    max(created_at) AS latest_created_at, count(*) AS frequency
                FROM normalized
                WHERE description <> '' AND strpos(lower(description) COLLATE "C", term) > 0
                GROUP BY key, is_prefix
                ORDER BY is_prefix DESC, latest_created_at DESC, frequency DESC, key ASC
                LIMIT 5
            ),
            selected_expenses AS MATERIALIZED (
                SELECT normalized.*, ranked_groups.key,
                    occurred_on BETWEEN from_date AND to_date AS in_window
                FROM normalized
                JOIN ranked_groups ON lower(normalized.description) COLLATE "C" = ranked_groups.key
                CROSS JOIN parameters
            ),
            spellings AS (
                SELECT DISTINCT ON (key) key, description
                FROM selected_expenses
                ORDER BY key, created_at DESC, id DESC
            ),
            amounts AS (
                SELECT key,
                    count(DISTINCT date_trunc('month', occurred_on)) FILTER (WHERE in_window) AS represented_months,
                    min(amount) FILTER (WHERE in_window) AS minimum_amount,
                    max(amount) FILTER (WHERE in_window) AS maximum_amount
                FROM selected_expenses
                GROUP BY key
            )
            SELECT ranked_groups.key, spellings.description,
                amounts.represented_months, amounts.minimum_amount, amounts.maximum_amount
            FROM ranked_groups
            JOIN spellings USING (key)
            JOIN amounts USING (key)
            ORDER BY ranked_groups.is_prefix DESC, ranked_groups.latest_created_at DESC,
                ranked_groups.frequency DESC, ranked_groups.key ASC
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
