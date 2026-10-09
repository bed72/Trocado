<?php

declare(strict_types=1);

namespace App\Insights\Domain\ValueObjects;

use App\Insights\Domain\Enums\InsightGroupEnum;
use App\Insights\Domain\Enums\InsightHistoryStateEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;

use function in_array;

final readonly class InsightCandidateValueObject
{
    public function __construct(
        public InsightTypeEnum $type,
        public InsightPeriodValueObject $analysisPeriod,
        public ?string $category = null,
        public ?InsightRatioValueObject $ratio = null,
        public ?InsightHistoryStateEnum $historyState = null,
        public ?InsightPeriodValueObject $comparisonPeriod = null,
    ) {
        $isTotalComparison = in_array($type, [InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease], true);
        $needsRatio = in_array($type, [InsightTypeEnum::CategoryConcentration, InsightTypeEnum::ExpenseConcentration,
            InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease, InsightTypeEnum::CategoryReview], true);
        $needsCategory = in_array($type, [InsightTypeEnum::CategoryConcentration, InsightTypeEnum::ExpenseConcentration,
            InsightTypeEnum::CategoryLeadStreak, InsightTypeEnum::CategoryReview], true);

        if ($needsRatio !== ($ratio !== null) || $needsCategory !== ($category !== null)
            || $isTotalComparison !== ($comparisonPeriod !== null)
            || ($type === InsightTypeEnum::InsufficientHistory) !== ($historyState !== null)) {
            throw new InvalidInsightAnalysisException('Os fatos do candidato não correspondem ao tipo de insight.');
        }

        if ($category === '' || ($type === InsightTypeEnum::CategoryReview && $category !== 'other')
            || (in_array($type, [InsightTypeEnum::CategoryConcentration, InsightTypeEnum::CategoryLeadStreak], true) && $category === 'other')) {
            throw new InvalidInsightAnalysisException('A categoria não é válida para o candidato.');
        }

        if ($isTotalComparison && ! $analysisPeriod->hasSameDurationAs($comparisonPeriod)) {
            throw new InvalidInsightAnalysisException('Uma comparação exige períodos de mesma duração.');
        }
    }

    public function isFinancialObservation(): bool
    {
        return $this->type->group() !== InsightGroupEnum::Onboarding;
    }

    public function period(): ?InsightPeriodValueObject
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
