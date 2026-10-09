<?php

declare(strict_types=1);

namespace App\Insights\Presentation\Http\Responses;

use App\Insights\Application\Data\InsightOutput;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\JsonApi\JsonApiResource;

/** @property InsightOutput $resource */
final class InsightResponse extends JsonApiResource
{
    public function toId(Request $request): string
    {
        return $this->resource->id;
    }

    public function toType(Request $request): string
    {
        return 'insights';
    }

    public function toAttributes(Request $request): array
    {
        return [
            'title' => $this->resource->title,
            'type' => $this->resource->type->value,
            'group' => $this->resource->group->value,
            'description' => $this->resource->description,
            'period' => $this->resource->period === null ? null : [
                'to' => $this->resource->period->to(),
                'from' => $this->resource->period->from(),
                'comparison' => $this->resource->comparisonPeriod === null ? null : [
                    'to' => $this->resource->comparisonPeriod->to(),
                    'from' => $this->resource->comparisonPeriod->from(),
                ],
            ],
        ];
    }
}
