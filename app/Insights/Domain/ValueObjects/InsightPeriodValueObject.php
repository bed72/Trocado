<?php

declare(strict_types=1);

namespace App\Insights\Domain\ValueObjects;

use App\Insights\Domain\Exceptions\InvalidInsightPeriodException;
use DateTimeImmutable;
use DateTimeZone;

final readonly class InsightPeriodValueObject
{
    private function __construct(private string $from, private string $to) {}

    public function to(): string
    {
        return $this->to;
    }

    public function from(): string
    {
        return $this->from;
    }

    public function equals(self $other): bool
    {
        return $this->from === $other->from && $this->to === $other->to;
    }

    public function hasSameDurationAs(self $other): bool
    {
        return $this->days() === $other->days();
    }

    public function days(): int
    {
        $timezone = new DateTimeZone(timezone: 'UTC');
        $to = new DateTimeImmutable(datetime: $this->to, timezone: $timezone);
        $from = new DateTimeImmutable(datetime: $this->from, timezone: $timezone);

        return (int) $from->diff(targetObject: $to)->format(format: '%a') + 1;
    }

    public static function fromDates(string $from, string $to): self
    {
        foreach ([$from, $to] as $value) {
            $date = DateTimeImmutable::createFromFormat(
                format: '!Y-m-d',
                datetime: $value,
                timezone: new DateTimeZone(timezone: 'UTC'),
            );

            if ($date === false || $date->format(format: 'Y-m-d') !== $value) {
                throw new InvalidInsightPeriodException(message: 'O período deve conter datas válidas.');
            }
        }

        if ($from > $to) {
            throw new InvalidInsightPeriodException(message: 'O início do período não pode ser posterior ao fim.');
        }

        return new self(from: $from, to: $to);
    }
}
