<?php

declare(strict_types=1);

namespace App\Notifications\Application\UseCases;

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\TransactionPort;
use App\Core\Application\Ports\UserPort;
use App\Notifications\Application\Exceptions\NotificationRegistrationNotFoundException;
use App\Notifications\Application\Ports\NotificationPort;
use App\Notifications\Application\Repositories\NotificationRegistrationRepository;
use App\Notifications\Domain\ValueObjects\NotificationValueObject;
use DateTimeImmutable;
use Throwable;

final readonly class DeleteNotificationUseCase
{
    public function __construct(
        private UserPort $userPort,
        private NotificationPort $recipientPort,
        private TransactionPort $transactionPort,
        private ObservabilityPort $observabilityPort,
        private NotificationRegistrationRepository $repository,
    ) {}

    public function execute(string $id, DateTimeImmutable $reference): void
    {
        $userId = $this->userPort->id();

        if (! NotificationValueObject::isUuid($id)) {
            throw new NotificationRegistrationNotFoundException;
        }

        $this->transactionPort->commit(function () use ($userId, $id, $reference): void {
            $this->recipientPort->lock($userId, $reference);

            if (! $this->repository->delete($userId, $id)) {
                throw new NotificationRegistrationNotFoundException;
            }

            $this->transactionPort->afterCommit(function () use ($userId, $id): void {
                try {
                    $this->observabilityPort->emit('push.registration.deleted', ['user_id' => $userId, 'registration_id' => $id]);
                } catch (Throwable) {
                    return;
                }
            });
        });
    }
}
