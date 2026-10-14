<?php

declare(strict_types=1);

namespace App\Notifications\Application\Data\Input;

use App\Notifications\Domain\ValueObjects\NotificationValueObject;
use DateTimeImmutable;
use SensitiveParameter;

final readonly class RegisterNotificationRegistrationInput
{
    public function __construct(
        public DateTimeImmutable $registeredAt,
        #[SensitiveParameter] public NotificationValueObject $destination,
    ) {}
}
