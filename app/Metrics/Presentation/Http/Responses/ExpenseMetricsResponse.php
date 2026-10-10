<?php

declare(strict_types=1);

namespace App\Metrics\Presentation\Http\Responses;

use App\Metrics\Application\Data\ExpenseCategoryMetricsOutput;
use App\Metrics\Application\Data\ExpenseMetricsOutput;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\JsonApi\JsonApiResource;

/** @property ExpenseMetricsOutput $resource */
final class ExpenseMetricsResponse extends JsonApiResource
{
    public function toId(Request $request): string
    {
        return $this->resource->id;
    }

    public function toType(Request $request): string
    {
        return 'expense-metrics';
    }

    public function toAttributes(Request $request): array
    {
        $attributes = [
            'end_date' => $this->resource->period->to(),
            'total_amount' => $this->resource->totalAmount,
            'start_date' => $this->resource->period->from(),
        ];

        if ($this->resource->categories !== null) {
            $attributes['categories'] = array_map(static fn (ExpenseCategoryMetricsOutput $category): array => [
                'category' => $category->category,
                'percentage' => $category->percentage,
                'total_amount' => $category->totalAmount,
            ], $this->resource->categories);
        }

        return $attributes;
    }
}
