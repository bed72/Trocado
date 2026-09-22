<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Responses;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\JsonApi\JsonApiResource;

final class SignUpResponse extends JsonApiResource
{
    public function toId(Request $request): string
    {
        return (string) $this->resource;
    }

    public function toType(Request $request): string
    {
        return 'sign-ups';
    }

    public function toAttributes(Request $request): array
    {
        return [];
    }

    public function resolveResourceData(Request $request): array
    {
        $data = parent::resolveResourceData(request: $request);
        $data['relationships'] = [
            'user' => [
                'data' => [
                    'type' => 'users',
                    'id' => (string) $this->resource,
                ],
            ],
        ];

        return $data;
    }
}
