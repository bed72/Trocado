<?php

declare(strict_types=1);

namespace Tests\Support\Notifications\Fixtures;

final class NotificationRegistrationFixture
{
    public const string Installation = 'bfb21c99-e2cb-4e18-8b73-b8fb0efc8d69';

    public const string OtherInstallation = 'daba5951-8748-4916-a942-7f85237983a6';

    /** @return array{data: array{type: string, attributes: array<string, string>}} */
    public static function payload(string $installation = self::Installation, string $identifier = 'FakeFcmToken:AbC_123', string $platform = 'android'): array
    {
        return ['data' => ['type' => 'push-registrations', 'attributes' => [
            'installation_id' => $installation,
            'platform' => $platform,
            'registration_kind' => 'token',
            'registration_identifier' => $identifier,
        ]]];
    }
}
