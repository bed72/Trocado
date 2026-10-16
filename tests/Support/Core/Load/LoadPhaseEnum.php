<?php

declare(strict_types=1);

namespace Tests\Support\Core\Load;

enum LoadPhaseEnum: string
{
    case Warmup = 'warmup';
    case Cleanup = 'cleanup';
    case Recovery = 'recovery';
    case Finished = 'finished';
    case Preflight = 'preflight';
    case Preparation = 'preparation';
    case Measurement = 'measurement';
}
