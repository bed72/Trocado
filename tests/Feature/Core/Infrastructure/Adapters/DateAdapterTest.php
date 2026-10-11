<?php

declare(strict_types=1);

use App\Core\Application\Ports\DatePort;
use App\Core\Infrastructure\Adapters\DateAdapter;
use Illuminate\Support\Facades\Date;

it('resolves the bound civil date using the application timezone rather than the runtime timezone', function (string $timezone, string $instant, string $expected): void {
    $originalTimezone = config('app.timezone');

    try {
        date_default_timezone_set('UTC');
        config()->set('app.timezone', $timezone);
        Date::setTestNow(new DateTimeImmutable($instant));
        $port = app(DatePort::class);

        expect($port)->toBeInstanceOf(DateAdapter::class)
            ->and($port->today())->toBe($expected);
    } finally {
        Date::setTestNow();
        config()->set('app.timezone', $originalTimezone);
    }
})->with([
    'UTC' => ['UTC', '2026-11-01 01:00:00 UTC', '2026-11-01'],
    'previous month in Brazil' => ['America/Sao_Paulo', '2026-11-01 01:00:00 UTC', '2026-10-31'],
    'next year in Kiritimati' => ['Pacific/Kiritimati', '2026-12-31 12:00:00 UTC', '2027-01-01'],
    'leap day' => ['America/Sao_Paulo', '2024-03-01 01:00:00 UTC', '2024-02-29'],
]);

it('reads the current clock and configuration on each call without caching a date', function (): void {
    $originalTimezone = config('app.timezone');

    try {
        config()->set('app.timezone', 'UTC');
        Date::setTestNow(new DateTimeImmutable('2026-11-01 01:00:00 UTC'));
        $port = app(DatePort::class);
        expect($port->today())->toBe('2026-11-01');

        config()->set('app.timezone', 'America/Sao_Paulo');
        expect($port->today())->toBe('2026-10-31');

        Date::setTestNow(new DateTimeImmutable('2026-11-01 04:00:00 UTC'));
        expect($port->today())->toBe('2026-11-01');
    } finally {
        Date::setTestNow();
        config()->set('app.timezone', $originalTimezone);
    }
});
