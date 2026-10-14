<?php

declare(strict_types=1);

namespace App\Notifications\Presentation\Http\Responses;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\JsonApi\JsonApiResource;

final class NotificationResponse extends JsonApiResource
{
    public function toId(Request $request): string
    {
        return $this->resource->id;
    }

    public function toType(Request $request): string
    {
        return 'push-registrations';
    }

    public function toAttributes(Request $request): array
    {
        return [
            'installation_id' => $this->resource->destination->installationId,
            'platform' => $this->resource->destination->platform->value,
            'provider' => 'fcm',
            'last_registered_at' => $this->resource->lastRegisteredAt->format(DATE_ATOM),
        ];
    }
}
