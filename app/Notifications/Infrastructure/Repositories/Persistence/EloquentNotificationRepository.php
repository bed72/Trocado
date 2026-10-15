<?php

declare(strict_types=1);

namespace App\Notifications\Infrastructure\Repositories\Persistence;

use App\Notifications\Application\Exceptions\NotificationRegistrationPersistenceException;
use App\Notifications\Application\Exceptions\NotificationRegistrationRaceException;
use App\Notifications\Application\Repositories\NotificationRegistrationRepository;
use App\Notifications\Domain\Entities\NotificationRegistrationEntity;
use App\Notifications\Domain\Enums\NotificationPlatformEnum;
use App\Notifications\Domain\ValueObjects\NotificationValueObject;
use App\Notifications\Infrastructure\Repositories\Persistence\Models\NotificationModel;
use DateTimeImmutable;
use Illuminate\Database\QueryException;
use Illuminate\Support\Str;
use SensitiveParameter;

use function in_array;

final readonly class EloquentNotificationRepository implements NotificationRegistrationRepository
{
    public function lock(#[SensitiveParameter] NotificationValueObject $destination): array
    {
        return $this->execute(fn (): array => NotificationModel::query()
            ->where('installation_id', $destination->installationId)
            ->orWhere('identifier_fingerprint', $this->fingerprint($destination))
            ->orderBy('id')->lockForUpdate()->get()
            ->map($this->entity(...))
            ->all());
    }

    public function create(string $userId, string $sessionId, #[SensitiveParameter] NotificationValueObject $destination, DateTimeImmutable $reference): NotificationRegistrationEntity
    {
        $registration = new NotificationRegistrationEntity(
            id: (string) Str::uuid7(),
            userId: $userId,
            sessionId: $sessionId,
            generation: 1,
            lastRegisteredAt: $reference,
            destination: $destination,
        );
        $this->write(new NotificationModel, $registration);

        return $registration;
    }

    public function update(#[SensitiveParameter] NotificationRegistrationEntity $registration): void
    {
        $this->execute(function () use ($registration): void {
            $model = NotificationModel::query()->where('user_id', $registration->userId)->findOrFail($registration->id);
            $this->write($model, $registration);
        });
    }

    public function delete(string $userId, string $id): bool
    {
        return $this->execute(fn (): bool => NotificationModel::query()
            ->where('user_id', $userId)->whereKey($id)->delete() === 1);
    }

    private function write(#[SensitiveParameter] NotificationModel $model, #[SensitiveParameter] NotificationRegistrationEntity $registration): void
    {
        $this->execute(function () use ($model, $registration): void {
            $attributes = [
                'provider' => 'fcm',
                'id' => $registration->id,
                'user_id' => $registration->userId,
                'session_id' => $registration->sessionId,
                'generation' => $registration->generation,
                'last_registered_at' => $registration->lastRegisteredAt,
                'platform' => $registration->destination->platform->value,
                'installation_id' => $registration->destination->installationId,
                'registration_kind' => $registration->destination->registrationKind,
                'identifier_fingerprint' => $this->fingerprint($registration->destination),
            ];

            if (! $model->exists || $model->getAttribute('registration_identifier') !== $registration->destination->identifier) {
                $attributes['registration_identifier'] = $registration->destination->identifier;
            }

            $model->forceFill($attributes)->save();
        });
    }

    private function fingerprint(#[SensitiveParameter] NotificationValueObject $destination): string
    {
        return hash('sha256', "fcm\0token\0{$destination->identifier}");
    }

    private function entity(#[SensitiveParameter] NotificationModel $model): NotificationRegistrationEntity
    {
        return new NotificationRegistrationEntity(
            id: (string) $model->getKey(),
            userId: $model->getAttribute('user_id'),
            sessionId: $model->getAttribute('session_id'),
            generation: $model->getAttribute('generation'),
            lastRegisteredAt: DateTimeImmutable::createFromInterface($model->getAttribute('last_registered_at')),
            destination: new NotificationValueObject(
                installationId: $model->getAttribute('installation_id'),
                registrationKind: $model->getAttribute('registration_kind'),
                identifier: $model->getAttribute('registration_identifier'),
                platform: NotificationPlatformEnum::from($model->getAttribute('platform')),
            ),
        );
    }

    private function execute(#[SensitiveParameter] callable $operation): mixed
    {
        try {
            return $operation();
        } catch (QueryException $exception) {
            $state = $exception->errorInfo[0] ?? null;
            $detail = $exception->errorInfo[2] ?? '';

            if (in_array($state, ['40001', '40P01'], true)
                || ($state === '23505' && (str_contains($detail, 'notifications_installation_id_unique')
                    || str_contains($detail, 'notifications_identifier_fingerprint_unique')))) {
                throw new NotificationRegistrationRaceException;
            }

            throw new NotificationRegistrationPersistenceException;
        }
    }
}
