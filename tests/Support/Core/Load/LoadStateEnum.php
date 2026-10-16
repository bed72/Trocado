<?php

declare(strict_types=1);

namespace Tests\Support\Core\Load;

enum LoadStateEnum: string
{
    case Failed = 'Failed';
    case Pending = 'Pending';
    case Running = 'Running';
    case Blocked = 'Blocked';
    case Passed = 'Passed';
    case Aborted = 'Aborted';
    case Calibration = 'Calibration';
    case Inconclusive = 'Inconclusive';
}
