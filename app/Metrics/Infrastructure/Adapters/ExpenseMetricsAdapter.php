<?php

declare(strict_types=1);

namespace App\Metrics\Infrastructure\Adapters;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Metrics\Application\Data\ExpenseCategoryTotalOutput;
use App\Metrics\Application\Data\ExpenseMetricsProjectionOutput;
use App\Metrics\Application\Ports\ExpenseMetricsPort;
use App\Metrics\Domain\Enums\ExpenseMetricsGroupingEnum;
use Illuminate\Support\Facades\DB;

final class ExpenseMetricsAdapter implements ExpenseMetricsPort
{
    public function summarize(
        int $userId,
        DatePeriodValueObject $period,
        ExpenseMetricsGroupingEnum $grouping,
    ): ExpenseMetricsProjectionOutput {
        $query = DB::table('expenses')
            ->where('user_id', $userId)
            ->whereBetween('occurred_on', [$period->from(), $period->to()]);

        if ($grouping === ExpenseMetricsGroupingEnum::Total) {
            $row = $query->selectRaw('CAST(COALESCE(SUM(amount), 0) AS text) AS total_amount')->first();

            return new ExpenseMetricsProjectionOutput(totalAmount: $row->total_amount);
        }

        $rows = $query
            ->select('category')
            ->selectRaw('CAST(SUM(amount) AS text) AS category_amount')
            ->selectRaw('CAST(SUM(SUM(amount)) OVER () AS text) AS total_amount')
            ->groupBy('category')
            ->orderByRaw('SUM(amount) DESC')
            ->orderBy('category')
            ->get();

        if ($rows->isEmpty()) {
            return new ExpenseMetricsProjectionOutput(totalAmount: '0');
        }

        $categories = [];

        foreach ($rows as $row) {
            $categories[] = new ExpenseCategoryTotalOutput(
                category: $row->category,
                totalAmount: $row->category_amount,
            );
        }

        return new ExpenseMetricsProjectionOutput(
            categories: $categories,
            totalAmount: $rows->first()->total_amount,
        );
    }
}
