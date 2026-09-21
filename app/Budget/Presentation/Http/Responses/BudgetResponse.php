<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Responses;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\JsonApi\JsonApiRequest;
use Illuminate\Http\Resources\JsonApi\JsonApiResource;

final class BudgetResponse extends JsonApiResource
{
    public function toId(Request $request): string
    {
        return (string) $this->resource->id;
    }

    public function toType(Request $request): string
    {
        return 'budgets';
    }

    public function toAttributes(Request $request): array
    {
        return [
            'end_date' => $this->resource->endDate,
            'start_date' => $this->resource->startDate,
            'amount' => $this->resource->amount->cents(),
            'created_at' => $this->resource->createdAt?->format(format: DATE_ATOM),
            'updated_at' => $this->resource->updatedAt?->format(format: DATE_ATOM),
        ];
    }

    public function toLinks(Request $request): array
    {
        return ['self' => route(name: 'budgets.get', parameters: ['budget' => $this->resource->id])];
    }

    public function resolveResourceData(Request $request): array
    {
        $data = parent::resolveResourceData(request: $request);

        $recurrenceRequested = ! $request instanceof JsonApiRequest
            || ! $request->hasSparseFieldset(key: 'budgets')
            || in_array(needle: 'recurrence', haystack: $request->sparseFields(key: 'budgets'), strict: true);

        if ($this->resource->recurrenceId !== null && $recurrenceRequested) {
            $data['relationships'] = [
                'recurrence' => [
                    'data' => [
                        'type' => 'budget-recurrences',
                        'id' => (string) $this->resource->recurrenceId,
                    ],
                ],
            ];
        }

        return $data;
    }
}
