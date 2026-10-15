<?php

declare(strict_types=1);

namespace App\Notifications\Domain\Entities;

use App\Core\Domain\ValueObjects\UuidValueObject;
use App\Notifications\Domain\Exceptions\InvalidNotificationRegistrationException;
use App\Notifications\Domain\ValueObjects\NotificationValueObject;
use DateTimeImmutable;
use SensitiveParameter;

final readonly class NotificationRegistrationEntity
{
    public string $userId;

    public string $sessionId;

    public function __construct(
        public string $id,
        string $userId,
        string $sessionId,
        public int $generation,
        public DateTimeImmutable $lastRegisteredAt,
        #[SensitiveParameter] public NotificationValueObject $destination,
    ) {
        $this->userId = UuidValueObject::fromString($userId)->value();
        $this->sessionId = UuidValueObject::fromString($sessionId)->value();
        if (! NotificationValueObject::isUuid($id) || $generation < 1) {
            throw new InvalidNotificationRegistrationException('registration');
        }
    }

    public function synchronize(string $sessionId, #[SensitiveParameter] NotificationValueObject $destination, DateTimeImmutable $reference): self
    {
        $sessionId = UuidValueObject::fromString($sessionId)->value();
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
