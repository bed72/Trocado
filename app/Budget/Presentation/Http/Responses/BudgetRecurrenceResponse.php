<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Responses;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\JsonApi\JsonApiResource;

final class BudgetRecurrenceResponse extends JsonApiResource
{
    public function toId(Request $request): string
    {
        return (string) $this->resource->id;
    }

    public function toType(Request $request): string
    {
        return 'budget-recurrences';
    }

    public function toAttributes(Request $request): array
    {
        return [
            'status' => $this->resource->status->value,
            'amount' => $this->resource->amount->cents(),
            'next_start_date' => $this->resource->nextStartDate,
            'duration_in_days' => $this->resource->durationInDays,
            'ended_at' => $this->resource->endedAt?->format(format: DATE_ATOM),
            'blocked_at' => $this->resource->blockedAt?->format(format: DATE_ATOM),
            'created_at' => $this->resource->createdAt?->format(format: DATE_ATOM),
            'updated_at' => $this->resource->updatedAt?->format(format: DATE_ATOM),
        ];
    }

    public function toLinks(Request $request): array
    {
        return ['self' => route(name: 'budget-recurrences.get', parameters: ['recurrence' => $this->resource->id])];
    }
}
