<?php

declare(strict_types=1);

namespace App\Budget\Domain\Entities;

use App\Budget\Domain\Exceptions\InvalidBudgetDateRangeException;
use App\Budget\Domain\ValueObjects\MoneyValueObject;
use DateTimeImmutable;

final readonly class BudgetEntity
{
    public function __construct(
        public ?int $id,
        public string $endDate,
        public string $startDate,
        public MoneyValueObject $amount,
        public ?DateTimeImmutable $createdAt = null,
        public ?DateTimeImmutable $updatedAt = null,
        public ?int $recurrenceId = null,
    ) {
        if (! self::isCalendarDate(date: $startDate) || ! self::isCalendarDate(date: $endDate) || $startDate > $endDate) {
            throw new InvalidBudgetDateRangeException(message: 'O intervalo de datas deve ser válido e start_date não pode ser posterior a end_date.');
        }
    }

    private static function isCalendarDate(string $date): bool
    {
        if (preg_match(pattern: '/^\d{4}-\d{2}-\d{2}$/D', subject: $date) !== 1) {
            return false;
        }

        [$year, $month, $day] = array_map(callback: 'intval', array: explode(separator: '-', string: $date));

        return checkdate(month: $month, day: $day, year: $year);
    }
}
