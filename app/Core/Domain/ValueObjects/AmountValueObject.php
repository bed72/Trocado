<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObjects;

use App\Core\Domain\Exceptions\InvalidAmountException;
use Brick\Math\BigInteger;

final readonly class AmountValueObject
{
    private function __construct(private string $amount) {}

    public static function fromAmount(string $amount): self
    {
        if (preg_match('/\A(?:0|[1-9][0-9]*)\z/', $amount) !== 1) {
            throw new InvalidAmountException('O valor deve conter centavos inteiros não negativos em formato canônico.');
        }

        return new self(amount: $amount);
    }

    public function amount(): string
    {
        return $this->amount;
    }

    public function isZero(): bool
    {
        return $this->amount === '0';
    }

    public function compareTo(self $other): int
    {
        return BigInteger::of($this->amount)->compareTo($other->amount);
    }

    public function isAtLeast(string $amount): bool
    {
        return $this->compareTo(self::fromAmount($amount)) >= 0;
    }

    public function plus(self $other): self
    {
        return new self(amount: (string) BigInteger::of($this->amount)->plus($other->amount));
    }

    public function absoluteDifference(self $other): self
    {
        return new self(amount: (string) BigInteger::of($this->amount)->minus($other->amount)->abs());
    }

    public function shareOf(self $total): RatioValueObject
    {
        return RatioValueObject::fromAmounts(numerator: $this, denominator: $total);
    }
}
