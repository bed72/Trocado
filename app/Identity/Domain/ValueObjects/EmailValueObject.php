<?php

declare(strict_types=1);

namespace App\Identity\Domain\ValueObjects;

use App\Identity\Domain\Exceptions\InvalidEmailException;

final readonly class EmailValueObject
{
    private function __construct(private string $value)
    {
        if (filter_var($value, FILTER_VALIDATE_EMAIL) === false) {
            throw new InvalidEmailException(message: 'O e-mail informado é inválido.');
        }
    }

    public static function fromString(string $value): self
    {
        return new self(value: strtolower(trim($value)));
    }

    public function value(): string
    {
        return $this->value;
    }

    public function equals(self $other): bool
    {
        return $this->value === $other->value;
    }
}
