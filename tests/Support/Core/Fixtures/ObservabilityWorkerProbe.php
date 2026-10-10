<?php

declare(strict_types=1);

namespace Tests\Support\Core\Fixtures;

use App\Core\Application\Ports\ObservabilityPort;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;

final class ObservabilityWorkerProbe implements ShouldQueue
{
    use Queueable;

    public function handle(ObservabilityPort $port): void
    {
        $port->emit('probe.worker', ['expense_id' => 1500]);
    }
}
