<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Responses;

use App\Expense\Application\Data\ExpenseSuggestionOutput;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\JsonApi\JsonApiResource;

/** @property ExpenseSuggestionOutput $resource */
final class ExpenseSuggestionResponse extends JsonApiResource
{
    public function toId(Request $request): string
    {
        return $this->resource->id;
    }

    public function toType(Request $request): string
    {
        return 'expense-suggestions';
    }

    public function toAttributes(Request $request): array
    {
        $attributes = ['description' => $this->resource->description];

        if ($this->resource->amount !== null) {
            $attributes['amount'] = $this->resource->amount;
        }

        return $attributes;
    }
}
