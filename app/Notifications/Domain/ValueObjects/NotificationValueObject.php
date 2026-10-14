<?php

declare(strict_types=1);

namespace App\Notifications\Domain\ValueObjects;

use App\Notifications\Domain\Enums\NotificationPlatformEnum;
use App\Notifications\Domain\Exceptions\InvalidNotificationRegistrationException;
use SensitiveParameter;

use function strlen;

final readonly class NotificationValueObject
{
    public string $installationId;

    public function __construct(
        string $installationId,
        public string $registrationKind,
        public NotificationPlatformEnum $platform,
        #[SensitiveParameter] public string $identifier,
    ) {
        if (! self::isUuid($installationId)) {
            throw new InvalidNotificationRegistrationException('installation_id');
        }

        if ($registrationKind !== 'token') {
            throw new InvalidNotificationRegistrationException('registration_kind');
        }

        if (! self::isIdentifier($identifier)) {
            throw new InvalidNotificationRegistrationException('registration_identifier');
        }

        $this->installationId = strtolower($installationId);
    }

    public static function isUuid(string $value): bool
    {
        return preg_match('/\A[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/Di', $value) === 1;
    }

    public static function isIdentifier(#[SensitiveParameter] string $value): bool
    {
        return strlen($value) >= 1 && strlen($value) <= 4096
            && preg_match('/\A[\x21-\x7e]+\z/D', $value) === 1;
    }
}
