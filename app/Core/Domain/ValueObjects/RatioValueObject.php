<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObjects;

use App\Core\Domain\Exceptions\InvalidRatioException;
use Brick\Math\BigInteger;
use Brick\Math\RoundingMode;

final readonly class RatioValueObject
{
    private function __construct(
        public AmountValueObject $numerator,
        public AmountValueObject $denominator,
    ) {}

    public static function fromAmounts(AmountValueObject $numerator, AmountValueObject $denominator): self
    {
        if ($denominator->isZero()) {
            throw new InvalidRatioException('Uma participação exige denominador positivo.');
        }

        return new self(numerator: $numerator, denominator: $denominator);
    }

    public static function fromShare(AmountValueObject $amount, AmountValueObject $total): self
    {
        $ratio = self::fromAmounts(numerator: $amount, denominator: $total);

        if ($amount->compareTo($total) > 0) {
            throw new InvalidRatioException('Uma participação não pode superar o total.');
        }

        return $ratio;
    }

    public function isAtLeastPercent(int $percent): bool
    {
        if ($percent < 0) {
            throw new InvalidRatioException('O percentual mínimo não pode ser negativo.');
        }

        return BigInteger::of($this->numerator->amount())->multipliedBy(100)
            ->isGreaterThanOrEqualTo(BigInteger::of($this->denominator->amount())->multipliedBy($percent));
    }

    public function roundedPercent(int $decimalPlaces = 0): string
    {
        if ($decimalPlaces < 0) {
            throw new InvalidRatioException('A quantidade de casas decimais não pode ser negativa.');
        }

        $rounded = (string) BigInteger::of($this->numerator->amount())
            ->multipliedBy(BigInteger::of(100)->multipliedBy(BigInteger::of(10)->power($decimalPlaces)))
            ->dividedBy($this->denominator->amount(), RoundingMode::HalfUp);

        if ($decimalPlaces === 0) {
            return $rounded;
        }

        $digits = str_pad($rounded, $decimalPlaces + 1, '0', STR_PAD_LEFT);

        return substr($digits, 0, -$decimalPlaces).'.'.substr($digits, -$decimalPlaces);
    }
}
