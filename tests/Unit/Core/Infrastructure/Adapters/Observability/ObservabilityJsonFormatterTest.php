<?php

declare(strict_types=1);

use App\Core\Infrastructure\Adapters\Observability\ObservabilityJsonFormatter;
use Monolog\Level;
use Monolog\LogRecord;

it('formats structural JSON without confusing legitimate IDs and timestamp digits with sensitive amounts', function (): void {
    $record = new LogRecord(
        datetime: new DateTimeImmutable('2026-10-10T15:00:00.001500+00:00'),
        channel: 'observability',
        level: Level::Info,
        message: 'expense.created',
        context: ['expense_id' => 1500, 'user_id' => 1500, 'category' => 'food'],
        extra: ['request_id' => 'request-1500'],
    );

    $json = (new ObservabilityJsonFormatter)->format($record);
    $decoded = json_decode($json, true, flags: JSON_THROW_ON_ERROR);

    expect($decoded)->toBe([
        'event' => 'expense.created', 'level' => 'INFO', 'timestamp' => '2026-10-10T15:00:00.001500+00:00',
        'request_id' => 'request-1500', 'expense_id' => 1500, 'user_id' => 1500, 'category' => 'food',
    ])->not->toHaveKeys(['amount', 'description', 'password', 'token', 'payload'])
        ->and($json)->toEndWith("\n");
});
