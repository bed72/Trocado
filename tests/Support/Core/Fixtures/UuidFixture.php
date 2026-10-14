<?php

declare(strict_types=1);

namespace Tests\Support\Core\Fixtures;

use InvalidArgumentException;

final class UuidFixture
{
    public static function at(int $index): string
    {
        if ($index < 0 || $index > 0xFFFFFFFFFFFF) {
            throw new InvalidArgumentException('O índice da fixture UUIDv7 deve caber em 48 bits não negativos.');
        }

        return sprintf('017f22e2-79b0-7cc3-98c4-%012x', $index);
    }
}
