<?php

declare(strict_types=1);

namespace App\Identity\Domain\ValueObjects;

use App\Identity\Domain\Exceptions\InvalidPasswordException;
use SensitiveParameter;

final readonly class PasswordValueObject
{
    private function __construct(#[SensitiveParameter] private string $value)
    {
        if (mb_strlen($value) < 6) {
            throw new InvalidPasswordException(message: 'A senha deve possuir ao menos 6 caracteres.');
        }

        if (mb_strlen($value) > 12) {
            throw new InvalidPasswordException(message: 'A senha não pode exceder 12 caracteres.');
        }

        if (preg_match('/\p{Lu}/u', $value) !== 1) {
            throw new InvalidPasswordException(message: 'A senha deve possuir ao menos uma letra maiúscula.');
        }

        if (preg_match('/[0-9]/', $value) !== 1) {
            throw new InvalidPasswordException(message: 'A senha deve possuir ao menos um número.');
        }
    }

    public static function fromString(#[SensitiveParameter] string $value): self
    {
        return new self(value: $value);
    }

    public function value(): string
    {
        return $this->value;
    }
}
