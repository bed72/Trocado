<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObjects;

use App\Core\Domain\Exceptions\InvalidDatePeriodException;
use DateTimeImmutable;
use DateTimeZone;

final readonly class DatePeriodValueObject
{
    private function __construct(private string $from, private string $to) {}

    public static function monthContaining(string $referenceDate): self
    {
        self::validateDate($referenceDate);

        $reference = new DateTimeImmutable($referenceDate, new DateTimeZone('UTC'));

        return new self(from: $reference->format('Y-m-01'), to: $reference->format('Y-m-t'));
    }

    public function contains(string $date): bool
    {
        self::validateDate($date);

        return $date >= $this->from && $date <= $this->to;
    }

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

    public function startsAtMonthStart(): bool
    {
        return substr($this->from, 8) === '01';
    }

    public function isCompleteMonth(): bool
    {
        $from = new DateTimeImmutable($this->from, new DateTimeZone('UTC'));

        return $this->startsAtMonthStart() && $from->format('Y-m-t') === $this->to;
    }

    public function isPreviousMonthOf(self $other): bool
    {
        $otherFrom = new DateTimeImmutable($other->from, new DateTimeZone('UTC'));

        return substr($this->from, 0, 7) === $otherFrom->modify('first day of previous month')->format('Y-m')
            && substr($this->to, 0, 7) === substr($this->from, 0, 7);
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
        self::validateDate($from);
        self::validateDate($to);

        if ($from > $to) {
            throw new InvalidDatePeriodException(message: 'O início do período não pode ser posterior ao fim.');
        }

        return new self(from: $from, to: $to);
    }

    private static function validateDate(string $date): void
    {
        if (preg_match('/\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/', $date) !== 1
            || ! checkdate((int) substr($date, 5, 2), (int) substr($date, 8, 2), (int) substr($date, 0, 4))) {
            throw new InvalidDatePeriodException('O período deve conter datas civis válidas em Y-m-d.');
        }
    }
}
