<?php

declare(strict_types=1);

namespace App\Notifications\Application\Repositories;

use App\Notifications\Domain\Entities\NotificationRegistrationEntity;
use App\Notifications\Domain\ValueObjects\NotificationValueObject;
use DateTimeImmutable;
use SensitiveParameter;

interface NotificationRegistrationRepository
{
    public function delete(int $userId, string $id): bool;

    public function update(#[SensitiveParameter] NotificationRegistrationEntity $registration): void;

    /** @return list<NotificationRegistrationEntity> */
    public function lock(#[SensitiveParameter] NotificationValueObject $destination): array;

    public function create(int $userId, int $sessionId, #[SensitiveParameter] NotificationValueObject $destination, DateTimeImmutable $reference): NotificationRegistrationEntity;
}
