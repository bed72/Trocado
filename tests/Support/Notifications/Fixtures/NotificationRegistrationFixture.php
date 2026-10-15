<?php

declare(strict_types=1);

namespace Tests\Support\Notifications\Fixtures;

final class NotificationRegistrationFixture
{
    public const string Installation = '017f22e2-79b0-7cc3-98c4-000000000101';

    public const string OtherInstallation = '017f22e2-79b0-7cc3-98c4-000000000102';

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
