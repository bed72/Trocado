<?php

declare(strict_types=1);

namespace Tests\Support\Core\Load;

use RuntimeException;

final class LoadEngineGate
{
    public const REASON = 'Blocked: STEP 01 engine architecture and dynamic capabilities require decision 1.6 and executable proof; product scenarios require STEPs 03-06.';

    public static function assertReady(): never
    {
        throw new RuntimeException(self::REASON);
    }
}
