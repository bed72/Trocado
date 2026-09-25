<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Adapters\Observability;

use Monolog\Formatter\JsonFormatter;
use Monolog\LogRecord;

final class ObservabilityJsonFormatter extends JsonFormatter
{
    public function format(LogRecord $record): string
    {
        return $this->toJson([
            'event' => $record->message,
            'level' => $record->level->getName(),
            'timestamp' => $record->datetime->format('Y-m-d\TH:i:s.uP'),
            ...$record->context,
        ], true)."\n";
    }
}
