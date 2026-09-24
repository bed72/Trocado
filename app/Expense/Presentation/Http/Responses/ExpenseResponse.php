<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Responses;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\JsonApi\JsonApiResource;

final class ExpenseResponse extends JsonApiResource
{
    public function toId(Request $request): string
    {
        return (string) $this->resource->id;
    }

    public function toType(Request $request): string
    {
        return 'expenses';
    }

    public function toAttributes(Request $request): array
    {
        return [
            'amount' => $this->resource->amount,
            'occurred_on' => $this->resource->occurredOn,
            'description' => $this->resource->description,
            'category' => $this->resource->category->value,
            'created_at' => $this->resource->createdAt?->format(format: DATE_ATOM),
        ];
    }
}
