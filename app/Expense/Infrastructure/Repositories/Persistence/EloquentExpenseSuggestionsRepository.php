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

    /**
     * Sampling chooses an equivalent execution path; it never limits the ranked history.
     * MIN preserves the source collation for normalization after byte-exact grouping.
     */
    private function suggestionsSql(string $ownedSql): string
    {
        $directSql = $this->historySql(compact: false);
        $compactSql = $this->historySql(compact: true);

        return <<<SQL
            WITH owned AS NOT MATERIALIZED (
                {$ownedSql}
            ),
            search AS MATERIALIZED (
                SELECT lower(regexp_replace(CAST(? AS text), '^[[:space:]]+|[[:space:]]+$', '', 'g')) AS term,
                    CAST(? AS date) AS from_date, CAST(? AS date) AS to_date
            ),
            strategy AS MATERIALIZED (
                SELECT count(*) >= 256 AND count(DISTINCT description COLLATE "C") * 2 <= count(*) AS compact
                FROM (SELECT description FROM owned LIMIT 2048) sample
                CROSS JOIN search
                WHERE strpos(lower(description) COLLATE "C", term) > 0
            )
            SELECT history.key, history.description,
                history.represented_months, history.minimum_amount, history.maximum_amount
            FROM strategy
            CROSS JOIN LATERAL (
                ({$directSql})
                UNION ALL
                ({$compactSql})
            ) history
            ORDER BY history.is_prefix DESC, history.latest_created_at DESC,
                history.frequency DESC, history.key ASC
            SQL;
    }

    private function historySql(bool $compact): string
    {
        $normalizedSql = $compact
            ? <<<'SQL'
                SELECT original_description,
                    regexp_replace(original_description, '^[[:space:]]+|[[:space:]]+$', '', 'g') AS description,
                    latest_created_at, frequency, term
                FROM (
                    SELECT min(owned.description) AS original_description,
                        max(created_at) AS latest_created_at, count(*) AS frequency, term
                    FROM owned
                    CROSS JOIN search
                    WHERE strategy.compact AND strpos(lower(owned.description) COLLATE "C", term) > 0
                    GROUP BY owned.description COLLATE "C", term
                ) grouped
                SQL
            : <<<'SQL'
                SELECT owned.id, owned.amount, owned.occurred_on, owned.created_at,
                    regexp_replace(owned.description, '^[[:space:]]+|[[:space:]]+$', '', 'g') AS description,
                    search.term
                FROM owned
                CROSS JOIN search
                WHERE NOT strategy.compact AND strpos(lower(owned.description) COLLATE "C", term) > 0
                SQL;
        $latestCreatedAt = $compact ? 'latest_created_at' : 'created_at';
        $frequency = $compact ? 'sum(frequency)' : 'count(*)';
        $selectedSql = $compact
            ? <<<'SQL'
                SELECT owned.id, owned.amount, owned.occurred_on, owned.created_at,
                    normalized.description, ranked_groups.key,
                    owned.occurred_on BETWEEN from_date AND to_date AS in_window
                FROM normalized
                JOIN ranked_groups ON lower(normalized.description) COLLATE "C" = ranked_groups.key
                JOIN owned ON owned.description COLLATE "C" = normalized.original_description
                CROSS JOIN search
                SQL
            : <<<'SQL'
                SELECT normalized.*, ranked_groups.key,
                    occurred_on BETWEEN from_date AND to_date AS in_window
                FROM normalized
                JOIN ranked_groups ON lower(normalized.description) COLLATE "C" = ranked_groups.key
                CROSS JOIN search
                SQL;

        return <<<SQL
            WITH normalized AS MATERIALIZED (
                {$normalizedSql}
            ),
            ranked_groups AS MATERIALIZED (
                SELECT lower(description) COLLATE "C" AS key,
                    strpos(lower(description) COLLATE "C", term) = 1 AS is_prefix,
                    max({$latestCreatedAt}) AS latest_created_at, {$frequency} AS frequency
                FROM normalized
                WHERE description <> '' AND strpos(lower(description) COLLATE "C", term) > 0
                GROUP BY key, is_prefix
                ORDER BY is_prefix DESC, latest_created_at DESC, frequency DESC, key ASC
                LIMIT 5
            ),
            selected_expenses AS MATERIALIZED (
                {$selectedSql}
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
                amounts.represented_months, amounts.minimum_amount, amounts.maximum_amount,
                ranked_groups.is_prefix, ranked_groups.latest_created_at, ranked_groups.frequency
            FROM ranked_groups
            JOIN spellings USING (key)
            JOIN amounts USING (key)
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
