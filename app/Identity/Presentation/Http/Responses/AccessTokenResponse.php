<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Responses;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\JsonApi\JsonApiResource;

final class AccessTokenResponse extends JsonApiResource
{
    public function toId(Request $request): string
    {
        return (string) $this->resource->id;
    }

    public function toType(Request $request): string
    {
        return 'access-tokens';
    }

    public function toAttributes(Request $request): array
    {
        return [
            'token_type' => 'Bearer',
            'token' => $this->resource->token,
            'expires_at' => $this->resource->expiresAt->format(format: DATE_ATOM),
        ];
    }

    public function resolveResourceData(Request $request): array
    {
        $data = parent::resolveResourceData(request: $request);
        $data['relationships'] = [
            'user' => [
                'data' => [
                    'type' => 'users',
                    'id' => (string) $this->resource->userId,
                ],
            ],
        ];

        return $data;
    }
}
