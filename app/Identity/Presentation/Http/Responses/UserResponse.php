<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Responses;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\JsonApi\JsonApiResource;

final class UserResponse extends JsonApiResource
{
    public function toId(Request $request): string
    {
        return (string) $this->resource->id;
    }

    public function toType(Request $request): string
    {
        return 'users';
    }

    public function toAttributes(Request $request): array
    {
        return [
            'name' => $this->resource->name->value(),
            'email' => $this->resource->email->value(),
            'status' => $this->resource->status->value,
            'created_at' => $this->resource->createdAt?->format(format: DATE_ATOM),
            'updated_at' => $this->resource->updatedAt?->format(format: DATE_ATOM),
        ];
    }

    public function toLinks(Request $request): array
    {
        return ['self' => route(name: 'users.get', parameters: ['user' => $this->resource->id])];
    }
}
