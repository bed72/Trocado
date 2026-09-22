<?php

declare(strict_types=1);

namespace App\Identity\Domain\ValueObjects;

use App\Identity\Domain\Exceptions\InvalidNameException;

use function is_string;

final readonly class NameValueObject
{
    private function __construct(private string $value) {}

    public static function fromString(string $value): self
    {
        $normalizedValue = preg_replace(pattern: '/\s+/u', replacement: ' ', subject: trim($value));

        if (! is_string($normalizedValue) || $normalizedValue === '') {
            throw new InvalidNameException(message: 'O nome do usuário não pode ser vazio.');
        }

        if (preg_match(pattern: '/^\p{L}+(?: \p{L}+)*$/u', subject: $normalizedValue) !== 1) {
            throw new InvalidNameException(message: 'O nome do usuário deve conter apenas letras e espaços.');
        }

        $letterCount = preg_match_all(pattern: '/\p{L}/u', subject: $normalizedValue);

        if ($letterCount < 2) {
            throw new InvalidNameException(message: 'O nome do usuário deve conter pelo menos 2 letras.');
        }

        if ($letterCount > 12) {
            throw new InvalidNameException(message: 'O nome do usuário não pode exceder 12 letras.');
        }

        return new self(value: $normalizedValue);
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
