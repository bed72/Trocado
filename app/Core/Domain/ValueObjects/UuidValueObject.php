<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObjects;

use App\Core\Domain\Exceptions\InvalidUuidException;

final readonly class UuidValueObject
{
    private function __construct(private string $value) {}

    public static function fromString(string $value): self
    {
        if (preg_match('/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i', $value) !== 1) {
            throw new InvalidUuidException('O identificador deve ser um UUIDv7 textual com variante RFC 9562.');
        }

        return new self(value: strtolower($value));
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
