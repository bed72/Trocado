<?php

declare(strict_types=1);

namespace App\Notifications\Domain\Entities;

use App\Notifications\Domain\Exceptions\InvalidNotificationRegistrationException;
use App\Notifications\Domain\ValueObjects\NotificationValueObject;
use DateTimeImmutable;
use SensitiveParameter;

final readonly class NotificationRegistrationEntity
{
    public function __construct(
        public string $id,
        public int $userId,
        public int $sessionId,
        public int $generation,
        public DateTimeImmutable $lastRegisteredAt,
        #[SensitiveParameter] public NotificationValueObject $destination,
    ) {
        if (! NotificationValueObject::isUuid($id) || $userId < 1 || $sessionId < 1 || $generation < 1) {
            throw new InvalidNotificationRegistrationException('registration');
        }
    }

    public function synchronize(int $sessionId, #[SensitiveParameter] NotificationValueObject $destination, DateTimeImmutable $reference): self
    {
        if ($destination->installationId !== $this->destination->installationId) {
            throw new InvalidNotificationRegistrationException('installation_id');
        }

        $changed = $sessionId !== $this->sessionId
            || $destination->platform !== $this->destination->platform
            || $destination->identifier !== $this->destination->identifier;

        return new self(
            id: $this->id,
            userId: $this->userId,
            sessionId: $sessionId,
            generation: $this->generation + (int) $changed,
            lastRegisteredAt: $reference,
            destination: $destination,
        );
    }
}
