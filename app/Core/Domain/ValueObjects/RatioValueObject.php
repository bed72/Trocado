<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObjects;

use App\Core\Domain\Exceptions\InvalidRatioException;
use Brick\Math\BigInteger;
use Brick\Math\RoundingMode;

final readonly class RatioValueObject
{
    private function __construct(
        public CentsValueObject $numerator,
        public CentsValueObject $denominator,
    ) {}

    public static function fromCents(CentsValueObject $numerator, CentsValueObject $denominator): self
    {
        if ($denominator->isZero()) {
            throw new InvalidRatioException('Uma participação exige denominador positivo.');
        }

        return new self(numerator: $numerator, denominator: $denominator);
    }

    public static function fromShare(CentsValueObject $cent, CentsValueObject $total): self
    {
        $ratio = self::fromCents(numerator: $cent, denominator: $total);

        if ($cent->compareTo($total) > 0) {
            throw new InvalidRatioException('Uma participação não pode superar o total.');
        }

        return $ratio;
    }

    public function isAtLeastPercent(int $percent): bool
    {
        if ($percent < 0) {
            throw new InvalidRatioException('O percentual mínimo não pode ser negativo.');
        }

        return BigInteger::of($this->numerator->cents())->multipliedBy(100)
            ->isGreaterThanOrEqualTo(BigInteger::of($this->denominator->cents())->multipliedBy($percent));
    }

    public function roundedPercent(int $decimalPlaces = 0): string
    {
        if ($decimalPlaces < 0) {
            throw new InvalidRatioException('A quantidade de casas decimais não pode ser negativa.');
        }

        $rounded = (string) BigInteger::of($this->numerator->cents())
            ->multipliedBy(BigInteger::of(100)->multipliedBy(BigInteger::of(10)->power($decimalPlaces)))
            ->dividedBy($this->denominator->cents(), RoundingMode::HalfUp);

        if ($decimalPlaces === 0) {
            return $rounded;
        }

        $digits = str_pad($rounded, $decimalPlaces + 1, '0', STR_PAD_LEFT);

        return substr($digits, 0, -$decimalPlaces).'.'.substr($digits, -$decimalPlaces);
    }
}
