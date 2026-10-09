<?php

declare(strict_types=1);

namespace App\Insights\Domain\ValueObjects;

use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use Brick\Math\BigInteger;

final readonly class InsightAmountValueObject
{
    private function __construct(private string $cents) {}

    public static function fromCents(string $cents): self
    {
        if (preg_match('/\A(?:0|[1-9][0-9]*)\z/', $cents) !== 1) {
            throw new InvalidInsightAnalysisException('O valor deve conter centavos inteiros não negativos em formato canônico.');
        }

        return new self(cents: $cents);
    }

    public function cents(): string
    {
        return $this->cents;
    }

    public function isZero(): bool
    {
        return $this->cents === '0';
    }

    public function compareTo(self $other): int
    {
        return BigInteger::of($this->cents)->compareTo($other->cents);
    }

    public function isAtLeast(string $cents): bool
    {
        return $this->compareTo(self::fromCents($cents)) >= 0;
    }

    public function plus(self $other): self
    {
        return new self(cents: (string) BigInteger::of($this->cents)->plus($other->cents));
    }

    public function absoluteDifference(self $other): self
    {
        return new self(cents: (string) BigInteger::of($this->cents)->minus($other->cents)->abs());
    }

    public function shareOf(self $total): InsightRatioValueObject
    {
        return InsightRatioValueObject::fromAmounts(numerator: $this, denominator: $total);
    }
}
