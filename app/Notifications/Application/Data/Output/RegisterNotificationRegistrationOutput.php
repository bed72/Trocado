<?php

declare(strict_types=1);

namespace App\Notifications\Application\Data\Output;

use App\Notifications\Domain\Entities\NotificationRegistrationEntity;
use SensitiveParameter;

final readonly class RegisterNotificationRegistrationOutput
{
    public function __construct(#[SensitiveParameter] public NotificationRegistrationEntity $registration, public bool $created) {}
}
