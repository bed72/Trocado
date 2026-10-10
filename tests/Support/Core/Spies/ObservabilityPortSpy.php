<?php

declare(strict_types=1);

namespace Tests\Support\Core\Spies;

use App\Core\Application\Ports\ObservabilityPort;

final class ObservabilityPortSpy implements ObservabilityPort
{
    /** @var list<array{event: string, attributes: array<string, bool|float|int|string|null>}> */
    public array $events = [];

    public function emit(string $event, array $attributes): void
    {
        $this->events[] = ['event' => $event, 'attributes' => $attributes];
    }
}
