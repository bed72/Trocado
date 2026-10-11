<?php

declare(strict_types=1);

namespace Tests\Support\Expense\Fixtures;

final class ExpenseCursorFixture
{
    public static function encode(array $payload): string
    {
        return rtrim(strtr(base64_encode(json_encode($payload, JSON_THROW_ON_ERROR)), '+/', '-_'), '=');
    }

    public static function payload(string $encoded): array
    {
        return json_decode(base64_decode(strtr($encoded, '-_', '+/'), true), true, flags: JSON_THROW_ON_ERROR);
    }
}
