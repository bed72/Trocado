<?php

declare(strict_types=1);

use App\Notifications\Domain\Entities\NotificationRegistrationEntity;
use App\Notifications\Domain\Enums\NotificationPlatformEnum;
use App\Notifications\Domain\Exceptions\InvalidNotificationRegistrationException;
use App\Notifications\Domain\ValueObjects\NotificationValueObject;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Notifications\Fixtures\NotificationRegistrationFixture;

it('preserves identity and generation on repeated synchronization', function (): void {
    $destination = new NotificationValueObject(installationId: NotificationRegistrationFixture::Installation, registrationKind: 'token', platform: NotificationPlatformEnum::Android, identifier: 'old-token');
    $registration = new NotificationRegistrationEntity(id: strtoupper(NotificationRegistrationFixture::Registration), userId: strtoupper(UuidFixture::at(1)), sessionId: UuidFixture::at(2), generation: 1, lastRegisteredAt: new DateTimeImmutable('2026-10-13T12:00:00Z'), destination: $destination);
    $updated = $registration->synchronize(strtoupper(UuidFixture::at(2)), $destination, new DateTimeImmutable('2026-10-13T13:00:00Z'));

    expect($updated->id)->toBe($registration->id)->and($updated->generation)->toBe(1)
        ->and($registration->id)->toBe(NotificationRegistrationFixture::Registration)
        ->and($updated->userId)->toBe(UuidFixture::at(1))->and($updated->sessionId)->toBe(UuidFixture::at(2))
        ->and($updated->lastRegisteredAt->format(DATE_ATOM))->toBe('2026-10-13T13:00:00+00:00');
});

it('increments generation for destination platform or session changes', function (int $session, NotificationPlatformEnum $platform, string $token): void {
    $registration = new NotificationRegistrationEntity(
        id: NotificationRegistrationFixture::Registration,
        userId: UuidFixture::at(1),
        sessionId: UuidFixture::at(2),
        generation: 4,
        lastRegisteredAt: new DateTimeImmutable('2026-10-13T12:00:00Z'),
        destination: new NotificationValueObject(installationId: NotificationRegistrationFixture::Installation, registrationKind: 'token', platform: NotificationPlatformEnum::Android, identifier: 'old-token'),
    );
    $updated = $registration->synchronize(UuidFixture::at($session),
        new NotificationValueObject(installationId: NotificationRegistrationFixture::Installation, registrationKind: 'token', platform: $platform, identifier: $token),
        new DateTimeImmutable('2026-10-13T13:00:00Z'));

    expect($updated->id)->toBe($registration->id)->and($updated->generation)->toBe(5)
        ->and($registration->generation)->toBe(4)->and($registration->destination->identifier)->toBe('old-token');
})->with([[2, NotificationPlatformEnum::Android, 'new-token'], [2, NotificationPlatformEnum::Ios, 'old-token'], [3, NotificationPlatformEnum::Android, 'old-token']]);

it('rejects invalid registration identities without HTTP or persistence', function (string $id): void {
    expect(fn () => new NotificationRegistrationEntity(
        id: $id, userId: UuidFixture::at(1), sessionId: UuidFixture::at(2), generation: 1,
        lastRegisteredAt: new DateTimeImmutable('2026-10-13T12:00:00Z'),
        destination: new NotificationValueObject(installationId: NotificationRegistrationFixture::Installation, registrationKind: 'token', platform: NotificationPlatformEnum::Android, identifier: 'fake-token'),
    ))->toThrow(InvalidNotificationRegistrationException::class);
})->with(['42', '017f22e2-79b0-4cc3-98c4-000000000201', '017f22e2-79b0-7cc3-c8c4-000000000201', ' '.NotificationRegistrationFixture::Registration]);
