<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Adapters\Observability;

use App\Core\Application\Ports\ObservabilityPort;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Log;
use Throwable;

final class ObservabilityAdapter implements ObservabilityPort
{
    public function emit(string $event, array $attributes): void
    {
        try {
            Log::channel(Config::string('logging.observability_channel'))->info($event, [
                'event' => $event,
                ...$attributes,
            ]);
        } catch (Throwable) {
            return;
        }
    }
}
