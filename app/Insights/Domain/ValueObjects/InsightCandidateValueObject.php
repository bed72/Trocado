<?php

declare(strict_types=1);

namespace App\Insights\Domain\ValueObjects;

use App\Core\Domain\ValueObjects\AmountValueObject;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Core\Domain\ValueObjects\RatioValueObject;
use App\Insights\Domain\Enums\InsightGroupEnum;
use App\Insights\Domain\Enums\InsightHistoryStateEnum;
use App\Insights\Domain\Enums\InsightPeriodModeEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;

use function in_array;

final readonly class InsightCandidateValueObject
{
    public function __construct(
        public InsightTypeEnum $type,
        public DatePeriodValueObject $analysisPeriod,
        public ?string $category = null,
        public ?RatioValueObject $ratio = null,
        public ?string $expenseOccurredOn = null,
        public ?string $expenseDescription = null,
        public ?InsightHistoryStateEnum $historyState = null,
        public ?DatePeriodValueObject $comparisonPeriod = null,
        public InsightPeriodModeEnum $mode = InsightPeriodModeEnum::Current,
        public ?AmountValueObject $selectedCategoryAmount = null,
    ) {
        $isTotalComparison = in_array($type, [InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease], true);
        $needsRatio = in_array($type, [InsightTypeEnum::CategoryConcentration, InsightTypeEnum::ExpenseConcentration,
            InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease, InsightTypeEnum::CategoryReview], true);
        $needsCategory = in_array($type, [InsightTypeEnum::CategoryConcentration, InsightTypeEnum::ExpenseConcentration,
            InsightTypeEnum::CategoryLeadStreak, InsightTypeEnum::CategoryReview], true);

        if ($needsRatio !== ($ratio !== null) || $needsCategory !== ($category !== null)
            || $isTotalComparison !== ($comparisonPeriod !== null)
            || ($type === InsightTypeEnum::InsufficientHistory) !== ($historyState !== null)
            || ($type === InsightTypeEnum::CategoryLeadStreak) !== ($selectedCategoryAmount !== null)
            || $selectedCategoryAmount?->isZero()) {
            throw new InvalidInsightAnalysisException('Os fatos do candidato não correspondem ao tipo de insight.');
        }

        if ($category === '' || ($type === InsightTypeEnum::CategoryReview && $category !== 'other')
            || (in_array($type, [InsightTypeEnum::CategoryConcentration, InsightTypeEnum::CategoryLeadStreak], true) && $category === 'other')) {
            throw new InvalidInsightAnalysisException('A categoria não é válida para o candidato.');
        }

        if ($isTotalComparison && $mode === InsightPeriodModeEnum::Current && ! $analysisPeriod->hasSameDurationAs($comparisonPeriod)) {
            throw new InvalidInsightAnalysisException('Uma comparação exige períodos de mesma duração.');
        }

        if ($isTotalComparison && $mode === InsightPeriodModeEnum::Closed
            && (! $analysisPeriod->isCompleteMonth() || ! $comparisonPeriod->isCompleteMonth()
                || ! $comparisonPeriod->isPreviousMonthOf($analysisPeriod))) {
            throw new InvalidInsightAnalysisException('Uma comparação encerrada exige meses completos consecutivos.');
        }

        if ($type === InsightTypeEnum::FirstExpense && $mode === InsightPeriodModeEnum::Closed) {
            throw new InvalidInsightAnalysisException('Primeira despesa não pertence a uma seleção histórica.');
        }

        if ($type === InsightTypeEnum::ExpenseConcentration) {
            if ($expenseOccurredOn === null || ! $analysisPeriod->contains($expenseOccurredOn)) {
                throw new InvalidInsightAnalysisException('A ocorrência do lançamento deve pertencer ao período do candidato.');
            }
        } elseif ($expenseDescription !== null || $expenseOccurredOn !== null) {
            throw new InvalidInsightAnalysisException('A identificação de lançamento pertence somente à concentração de despesa.');
        }
    }

    public function isFinancialObservation(): bool
    {
        return $this->type->group() !== InsightGroupEnum::Onboarding;
    }

    public function period(): ?DatePeriodValueObject
    {
        return $this->type->group() === InsightGroupEnum::Onboarding ? null : $this->analysisPeriod;
    }

    public function hasSameInformationAs(self $other): bool
    {
        $sameComparison = ($this->comparisonPeriod === null && $other->comparisonPeriod === null)
            || ($this->comparisonPeriod !== null && $other->comparisonPeriod !== null
                && $this->comparisonPeriod->equals($other->comparisonPeriod));

        return $this->type === $other->type
            && $this->category === $other->category
            && $this->historyState === $other->historyState
            && $this->analysisPeriod->equals($other->analysisPeriod)
            && $sameComparison;
    }

    public function supersedes(self $other): bool
    {
        if ($this->hasSameInformationAs($other)) {
            return true;
        }

        if ($this->category === null || $this->category !== $other->category) {
            return false;
        }

        if ($this->type === InsightTypeEnum::CategoryConcentration && $other->type === InsightTypeEnum::ExpenseConcentration) {
            return $this->analysisPeriod->equals($other->analysisPeriod);
        }

        if ($this->type === InsightTypeEnum::CategoryLeadStreak
            && in_array($other->type, [InsightTypeEnum::CategoryConcentration, InsightTypeEnum::ExpenseConcentration], true)) {
            $currentMonth = substr($this->analysisPeriod->to(), 0, 7);

            return $other->analysisPeriod->from() === "{$currentMonth}-01"
                && $other->analysisPeriod->to() === $this->analysisPeriod->to();
        }

        return false;
    }
}
