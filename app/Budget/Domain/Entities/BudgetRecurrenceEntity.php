<?php

declare(strict_types=1);

namespace App\Budget\Domain\Entities;

use App\Budget\Domain\Enums\RecurrenceStatusEnum;
use App\Budget\Domain\Exceptions\InvalidBudgetRecurrenceException;
use App\Budget\Domain\Exceptions\InvalidRecurrenceTransitionException;
use App\Budget\Domain\ValueObjects\MoneyValueObject;
use DateTimeImmutable;

final readonly class BudgetRecurrenceEntity
{
    public function __construct(
        public ?int $id,
        public int $durationInDays,
        public string $nextStartDate,
        public RecurrenceStatusEnum $status,
        public MoneyValueObject $amount,
        public ?DateTimeImmutable $endedAt = null,
        public ?DateTimeImmutable $createdAt = null,
        public ?DateTimeImmutable $updatedAt = null,
        public ?DateTimeImmutable $blockedAt = null,
    ) {
        if ($durationInDays < 1) {
            throw new InvalidBudgetRecurrenceException(message: 'A duração da recorrência deve ser maior que zero.');
        }

        if (! self::isCalendarDate(date: $nextStartDate)) {
            throw new InvalidBudgetRecurrenceException(message: 'A próxima data inicial da recorrência deve ser válida.');
        }

        $interval = self::calculateInterval(startDate: $nextStartDate, durationInDays: $durationInDays);
        self::calculateInterval(
            startDate: $interval[2]->format(format: 'Y-m-d'),
            durationInDays: $durationInDays,
        );
    }

    public static function fromInitialBudget(BudgetEntity $budget): self
    {
        $endDate = self::date(value: $budget->endDate);
        $startDate = self::date(value: $budget->startDate);

        return new self(
            id: null,
            amount: $budget->amount,
            status: RecurrenceStatusEnum::Active,
            durationInDays: $startDate->diff(targetObject: $endDate)->days + 1,
            nextStartDate: $endDate->modify(modifier: '+1 day')->format(format: 'Y-m-d'),
        );
    }

    /** @return array{startDate: string, endDate: string, nextStartDate: string} */
    public function pendingInterval(): array
    {
        [$startDate, $endDate, $nextStartDate] = self::calculateInterval(
            startDate: $this->nextStartDate,
            durationInDays: $this->durationInDays,
        );

        return [
            'startDate' => $startDate->format(format: 'Y-m-d'),
            'endDate' => $endDate->format(format: 'Y-m-d'),
            'nextStartDate' => $nextStartDate->format(format: 'Y-m-d'),
        ];
    }

    public function isDue(string $processingDate): bool
    {
        if (! self::isCalendarDate(date: $processingDate)) {
            throw new InvalidBudgetRecurrenceException(message: 'A data de processamento deve ser válida.');
        }

        return $this->status === RecurrenceStatusEnum::Active && $this->nextStartDate <= $processingDate;
    }

    public function updateTemplate(?MoneyValueObject $amount, ?int $durationInDays): self
    {
        if ($this->status === RecurrenceStatusEnum::Ended) {
            throw new InvalidRecurrenceTransitionException(message: 'Uma recorrência encerrada não pode ser alterada.');
        }

        return $this->copy(
            amount: $amount ?? $this->amount,
            durationInDays: $durationInDays ?? $this->durationInDays,
        );
    }

    public function block(DateTimeImmutable $blockedAt): self
    {
        if ($this->status !== RecurrenceStatusEnum::Active) {
            throw new InvalidRecurrenceTransitionException(message: 'Somente uma recorrência ativa pode ser bloqueada.');
        }

        return $this->copy(status: RecurrenceStatusEnum::Blocked, blockedAt: $blockedAt);
    }

    public function resume(): self
    {
        if ($this->status !== RecurrenceStatusEnum::Blocked) {
            throw new InvalidRecurrenceTransitionException(message: 'Somente uma recorrência bloqueada pode ser retomada.');
        }

        return $this->copy(status: RecurrenceStatusEnum::Active, clearBlockedAt: true);
    }

    public function end(DateTimeImmutable $endedAt): self
    {
        if ($this->status === RecurrenceStatusEnum::Ended) {
            throw new InvalidRecurrenceTransitionException(message: 'Uma recorrência encerrada não pode ser encerrada novamente.');
        }

        return $this->copy(status: RecurrenceStatusEnum::Ended, endedAt: $endedAt);
    }

    public function advanceToNextInterval(): self
    {
        if ($this->status !== RecurrenceStatusEnum::Active) {
            throw new InvalidRecurrenceTransitionException(message: 'Somente uma recorrência ativa pode avançar.');
        }

        return $this->copy(nextStartDate: $this->pendingInterval()['nextStartDate']);
    }

    private function copy(
        ?RecurrenceStatusEnum $status = null,
        ?MoneyValueObject $amount = null,
        ?int $durationInDays = null,
        ?string $nextStartDate = null,
        ?DateTimeImmutable $blockedAt = null,
        ?DateTimeImmutable $endedAt = null,
        bool $clearBlockedAt = false,
    ): self {
        return new self(
            id: $this->id,
            createdAt: $this->createdAt,
            updatedAt: $this->updatedAt,
            amount: $amount ?? $this->amount,
            status: $status ?? $this->status,
            endedAt: $endedAt ?? $this->endedAt,
            nextStartDate: $nextStartDate ?? $this->nextStartDate,
            durationInDays: $durationInDays ?? $this->durationInDays,
            blockedAt: $clearBlockedAt ? null : ($blockedAt ?? $this->blockedAt),
        );
    }

    private static function date(string $value): DateTimeImmutable
    {
        return new DateTimeImmutable(datetime: $value);
    }

    /** @return array{DateTimeImmutable, DateTimeImmutable, DateTimeImmutable} */
    private static function calculateInterval(string $startDate, int $durationInDays): array
    {
        $start = self::date(value: $startDate);
        $end = $start->modify(modifier: sprintf('+%d days', $durationInDays - 1));
        $nextStart = $end === false ? false : $end->modify(modifier: '+1 day');

        if (
            $end === false
            || $nextStart === false
            || ! self::isCalendarDate(date: $end->format(format: 'Y-m-d'))
            || ! self::isCalendarDate(date: $nextStart->format(format: 'Y-m-d'))
        ) {
            throw new InvalidBudgetRecurrenceException(message: 'A duração excede o intervalo de datas suportado.');
        }

        return [$start, $end, $nextStart];
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
