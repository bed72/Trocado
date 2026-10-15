<?php

declare(strict_types=1);

namespace App\Notifications\Domain\ValueObjects;

use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Core\Domain\ValueObjects\UuidValueObject;
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
        try {
            $this->installationId = UuidValueObject::fromString($installationId)->value();
        } catch (InvalidUuidException) {
            throw new InvalidNotificationRegistrationException('installation_id');
        }

        if ($registrationKind !== 'token') {
            throw new InvalidNotificationRegistrationException('registration_kind');
        }

        if (! self::isIdentifier($identifier)) {
            throw new InvalidNotificationRegistrationException('registration_identifier');
        }
    }

    public static function isUuid(string $value): bool
    {
        try {
            UuidValueObject::fromString($value);

            return true;
        } catch (InvalidUuidException) {
            return false;
        }
    }

    public static function isIdentifier(#[SensitiveParameter] string $value): bool
    {
        return strlen($value) >= 1 && strlen($value) <= 4096
            && preg_match('/\A[\x21-\x7e]+\z/D', $value) === 1;
    }
}
