<?php

declare(strict_types=1);

namespace App\Insights\Domain\ValueObjects;

use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use Brick\Math\BigInteger;
use Brick\Math\RoundingMode;

final readonly class InsightRatioValueObject
{
    private function __construct(
        public InsightAmountValueObject $numerator,
        public InsightAmountValueObject $denominator,
    ) {}

    public static function fromAmounts(InsightAmountValueObject $numerator, InsightAmountValueObject $denominator): self
    {
        if ($denominator->isZero()) {
            throw new InvalidInsightAnalysisException('Uma participação exige denominador positivo.');
        }

        return new self(numerator: $numerator, denominator: $denominator);
    }

    public function isAtLeastPercent(int $percent): bool
    {
        if ($percent < 0) {
            throw new InvalidInsightAnalysisException('O percentual mínimo não pode ser negativo.');
        }

        return BigInteger::of($this->numerator->cents())->multipliedBy(100)
            ->isGreaterThanOrEqualTo(BigInteger::of($this->denominator->cents())->multipliedBy($percent));
    }

    public function roundedPercent(): string
    {
        return (string) BigInteger::of($this->numerator->cents())->multipliedBy(100)
            ->dividedBy($this->denominator->cents(), RoundingMode::HalfUp);
    }
}
