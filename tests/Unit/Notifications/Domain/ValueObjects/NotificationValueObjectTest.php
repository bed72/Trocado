<?php

declare(strict_types=1);

use App\Notifications\Domain\Enums\NotificationPlatformEnum;
use App\Notifications\Domain\Exceptions\InvalidNotificationRegistrationException;
use App\Notifications\Domain\ValueObjects\NotificationValueObject;
use Tests\Support\Notifications\Fixtures\NotificationRegistrationFixture;

it('preserves exact FCM bytes and canonicalizes only the local UUID', function (): void {
    $destination = new NotificationValueObject(installationId: strtoupper(NotificationRegistrationFixture::Installation), registrationKind: 'token', platform: NotificationPlatformEnum::Ios, identifier: 'AbC:def_-XYZ');

    expect($destination->identifier)->toBe('AbC:def_-XYZ')
        ->and($destination->installationId)->toBe(NotificationRegistrationFixture::Installation);
});

it('rejects invalid identifiers outside HTTP', function (string $identifier): void {
    expect(fn () => new NotificationValueObject(installationId: NotificationRegistrationFixture::Installation, registrationKind: 'token', platform: NotificationPlatformEnum::Android, identifier: $identifier))
        ->toThrow(InvalidNotificationRegistrationException::class);
})->with(['empty' => '', 'space' => ' token', 'newline' => "token\n", 'unicode' => 'tóken', 'control' => "abc\0def", 'too large' => str_repeat('a', 4097)]);

it('accepts the exact 4096 byte limit', function (): void {
    expect((new NotificationValueObject(installationId: NotificationRegistrationFixture::Installation, registrationKind: 'token', platform: NotificationPlatformEnum::Android, identifier: str_repeat('a', 4096)))->identifier)
        ->toHaveLength(4096);
});

it('rejects FID and malformed installation identities', function (): void {
    expect(fn () => new NotificationValueObject(installationId: NotificationRegistrationFixture::Installation, registrationKind: 'fid', platform: NotificationPlatformEnum::Android, identifier: 'fake'))
        ->toThrow(InvalidNotificationRegistrationException::class)
        ->and(fn () => new NotificationValueObject(installationId: 'device-id', registrationKind: 'token', platform: NotificationPlatformEnum::Android, identifier: 'fake'))
        ->toThrow(InvalidNotificationRegistrationException::class);
});

it('requires a textual RFC 9562 UUIDv7 installation outside HTTP', function (string $installation): void {
    expect(fn () => new NotificationValueObject(installationId: $installation, registrationKind: 'token', platform: NotificationPlatformEnum::Android, identifier: 'sensitive-token'))
        ->toThrow(InvalidNotificationRegistrationException::class);
})->with([
    'v1' => '017f22e2-79b0-1cc3-98c4-000000000101',
    'v4' => '017f22e2-79b0-4cc3-98c4-000000000101',
    'v6' => '017f22e2-79b0-6cc3-98c4-000000000101',
    'v8' => '017f22e2-79b0-8cc3-98c4-000000000101',
    'nil' => '00000000-0000-0000-0000-000000000000',
    'variant' => '017f22e2-79b0-7cc3-c8c4-000000000101',
    'numeric' => '42',
    'hash' => str_repeat('a', 64),
    'space' => ' '.NotificationRegistrationFixture::Installation,
    'newline' => NotificationRegistrationFixture::Installation."\n",
    'compact' => '017f22e279b07cc398c4000000000101',
]);
