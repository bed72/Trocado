<?php

declare(strict_types=1);

namespace App\Budget\Domain\ValueObjects;

use App\Budget\Domain\Exceptions\InvalidMoneyAmountException;

final readonly class MoneyValueObject
{
    private function __construct(private int $cents)
    {
        if ($cents < 0) {
            throw new InvalidMoneyAmountException(message: 'O valor em centavos não pode ser negativo.');
        }
    }

    public static function fromCents(int $cents): self
    {
        return new self(cents: $cents);
    }

    public function cents(): int
    {
        return $this->cents;
    }

    public function add(self $other): self
    {
        if ($this->cents > PHP_INT_MAX - $other->cents) {
            throw new InvalidMoneyAmountException(message: 'A soma dos valores excede o limite suportado.');
        }

        return new self(cents: $this->cents + $other->cents);
    }

    public function subtract(self $other): self
    {
        if ($other->cents > $this->cents) {
            throw new InvalidMoneyAmountException(message: 'A subtração não pode produzir valor negativo.');
        }

        return new self(cents: $this->cents - $other->cents);
    }

    public function equals(self $other): bool
    {
        return $this->cents === $other->cents;
    }
}
