<?php

declare(strict_types=1);

use App\Identity\Domain\ValueObjects\SessionPolicyValueObject;

it('issues a session for 30 calendar days without mutating the issuance date', function (): void {
    $issuedAt = new DateTimeImmutable('2026-01-01T12:00:00+00:00');
    $expiry = (new SessionPolicyValueObject)->initialExpiry($issuedAt);

    expect($expiry->format(DATE_ATOM))->toBe('2026-01-31T12:00:00+00:00')
        ->and($issuedAt->format(DATE_ATOM))->toBe('2026-01-01T12:00:00+00:00');
});

it('extends only within the inclusive window without shortening or reviving a session', function (string $expiresAt, string $reference, ?string $expected): void {
    $expiry = (new SessionPolicyValueObject)->extendedExpiry(
        issuedAt: new DateTimeImmutable('2026-01-01T12:00:00+00:00'),
        expiresAt: new DateTimeImmutable($expiresAt),
        reference: new DateTimeImmutable($reference),
    );

    expect($expiry?->format(DATE_ATOM))->toBe($expected);
})->with([
    'one second before window' => ['2026-01-31T12:00:00+00:00', '2026-01-16T11:59:59+00:00', null],
    'inclusive window' => ['2026-01-31T12:00:00+00:00', '2026-01-16T12:00:00+00:00', '2026-02-15T12:00:00+00:00'],
    'expiry reached' => ['2026-01-31T12:00:00+00:00', '2026-01-31T12:00:00+00:00', null],
    'already expired' => ['2026-01-31T12:00:00+00:00', '2026-02-01T12:00:00+00:00', null],
    'cap at absolute limit' => ['2026-03-22T12:00:00+00:00', '2026-03-17T12:00:00+00:00', '2026-04-01T12:00:00+00:00'],
    'already at absolute limit' => ['2026-04-01T12:00:00+00:00', '2026-03-22T12:00:00+00:00', null],
    'never shorten a stored expiry' => ['2026-04-05T12:00:00+00:00', '2026-03-22T12:00:00+00:00', null],
    'absolute limit reached' => ['2026-04-05T12:00:00+00:00', '2026-04-01T12:00:00+00:00', null],
]);

it('rejects either expiry boundary even when the other one is still in the future', function (string $expiresAt, string $reference, bool $expected): void {
    expect((new SessionPolicyValueObject)->isValid(
        issuedAt: new DateTimeImmutable('2026-01-01T12:00:00+00:00'),
        expiresAt: new DateTimeImmutable($expiresAt),
        reference: new DateTimeImmutable($reference),
    ))->toBe($expected);
})->with([
    'valid session' => ['2026-01-31T12:00:00+00:00', '2026-01-16T12:00:00+00:00', true],
    'individual expiry' => ['2026-01-31T12:00:00+00:00', '2026-01-31T12:00:00+00:00', false],
    'absolute expiry with later stored expiry' => ['2027-01-01T12:00:00+00:00', '2026-04-01T12:00:00+00:00', false],
]);
