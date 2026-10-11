<?php

declare(strict_types=1);

namespace App\Identity\Domain\ValueObjects;

use DateTimeImmutable;

final readonly class SessionPolicyValueObject
{
    private const int ValidityDays = 30;

    private const int MaximumAgeDays = 90;

    private const int ExtensionWindowDays = 15;

    public function initialExpiry(DateTimeImmutable $issuedAt): DateTimeImmutable
    {
        return $issuedAt->modify('+'.self::ValidityDays.' days');
    }

    public function isValid(DateTimeImmutable $issuedAt, DateTimeImmutable $expiresAt, DateTimeImmutable $reference): bool
    {
        return $expiresAt > $reference && $this->absoluteExpiry($issuedAt) > $reference;
    }

    public function extendedExpiry(DateTimeImmutable $issuedAt, DateTimeImmutable $expiresAt, DateTimeImmutable $reference): ?DateTimeImmutable
    {
        if (! $this->isValid($issuedAt, $expiresAt, $reference)
            || $expiresAt > $reference->modify('+'.self::ExtensionWindowDays.' days')) {
            return null;
        }

        $newExpiry = min($this->initialExpiry($reference), $this->absoluteExpiry($issuedAt));

        return $newExpiry > $expiresAt ? $newExpiry : null;
    }

    private function absoluteExpiry(DateTimeImmutable $issuedAt): DateTimeImmutable
    {
        return $issuedAt->modify('+'.self::MaximumAgeDays.' days');
    }
}
