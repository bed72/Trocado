<?php

declare(strict_types=1);

namespace App\Insights\Domain\ValueObjects;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Domain\Enums\InsightPeriodModeEnum;
use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use DateTimeImmutable;
use DateTimeZone;

final readonly class InsightAnalysisPeriodValueObject
{
    public InsightPeriodModeEnum $mode;

    public DatePeriodValueObject $twoMonthsAgo;

    public DatePeriodValueObject $currentMonth;

    public DatePeriodValueObject $previousMonth;

    public ?DatePeriodValueObject $currentComparison;

    public ?DatePeriodValueObject $previousComparison;

    public function __construct(string $queryDate, DatePeriodValueObject $selectedMonth)
    {
        $queryMonth = DatePeriodValueObject::monthContaining($queryDate);

        if (! $selectedMonth->isCompleteMonth()) {
            throw new InvalidInsightAnalysisException('A seleção deve representar um mês civil completo.');
        }

        if ($selectedMonth->from() > $queryMonth->from()) {
            throw new InvalidInsightAnalysisException('O mês selecionado não pode ser futuro.');
        }

        if ($selectedMonth->from() < '0001-03-01') {
            throw new InvalidInsightAnalysisException('Os dois meses antecedentes devem ser representáveis.');
        }

        $start = new DateTimeImmutable($selectedMonth->from(), new DateTimeZone('UTC'));
        $this->mode = $selectedMonth->equals($queryMonth) ? InsightPeriodModeEnum::Current : InsightPeriodModeEnum::Closed;
        $this->currentMonth = $this->mode === InsightPeriodModeEnum::Current
            ? DatePeriodValueObject::fromDates($selectedMonth->from(), $queryDate)
            : $selectedMonth;
        $this->previousMonth = $selectedMonth->previousMonth();
        $this->twoMonthsAgo = $this->previousMonth->previousMonth();

        if ($this->mode === InsightPeriodModeEnum::Closed) {
            $this->currentComparison = $this->currentMonth;
            $this->previousComparison = $this->previousMonth;

            return;
        }

        $days = min((int) substr($queryDate, 8) - 1, $this->previousMonth->days());
        $this->currentComparison = $days > 0
            ? DatePeriodValueObject::fromDates($selectedMonth->from(), $start->modify('+'.($days - 1).' days')->format('Y-m-d'))
            : null;
        $this->previousComparison = $days > 0
            ? DatePeriodValueObject::fromDates($this->previousMonth->from(), substr($this->previousMonth->from(), 0, 8).sprintf('%02d', $days))
            : null;
    }

    /** @return array<string, DatePeriodValueObject> */
    public function periods(): array
    {
        $periods = [
            'current_month' => $this->currentMonth,
            'previous_month' => $this->previousMonth,
            'two_months_ago' => $this->twoMonthsAgo,
        ];

        if ($this->currentComparison !== null && $this->previousComparison !== null) {
            $periods['current_comparison'] = $this->currentComparison;
            $periods['previous_comparison'] = $this->previousComparison;
        }

        return $periods;
    }
}
