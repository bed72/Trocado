<?php

declare(strict_types=1);

namespace App\Notifications\Application\UseCases;

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\TransactionPort;
use App\Core\Application\Ports\UserPort;
use App\Notifications\Application\Data\Input\RegisterNotificationRegistrationInput;
use App\Notifications\Application\Data\Output\RegisterNotificationRegistrationOutput;
use App\Notifications\Application\Exceptions\NotificationRegistrationConflictException;
use App\Notifications\Application\Exceptions\NotificationRegistrationRaceException;
use App\Notifications\Application\Ports\NotificationPort;
use App\Notifications\Application\Repositories\NotificationRegistrationRepository;
use SensitiveParameter;
use Throwable;

final readonly class CreateNotificationUseCase
{
    public function __construct(
        private UserPort $userPort,
        private NotificationPort $recipientPort,
        private TransactionPort $transactionPort,
        private ObservabilityPort $observabilityPort,
        private NotificationRegistrationRepository $repository,
    ) {}

    public function execute(#[SensitiveParameter] RegisterNotificationRegistrationInput $input): RegisterNotificationRegistrationOutput
    {
        $userId = $this->userPort->id();

        for ($attempt = 0; $attempt < 3; $attempt++) {
            try {
                return $this->transactionPort->commit(function () use ($userId, $input): RegisterNotificationRegistrationOutput {
                    $sessionId = $this->recipientPort->lock($userId, $input->registeredAt);
                    $existing = null;

                    foreach ($this->repository->lock($input->destination) as $registration) {
                        if ($registration->userId !== $userId
                            || $registration->destination->installationId !== $input->destination->installationId) {
                            throw new NotificationRegistrationConflictException;
                        }

                        $existing = $registration;
                    }

                    if ($existing === null) {
                        $output = new RegisterNotificationRegistrationOutput(
                            $this->repository->create($userId, $sessionId, $input->destination, $input->registeredAt),
                            true,
                        );
                    } else {
                        $updated = $existing->synchronize($sessionId, $input->destination, $input->registeredAt);
                        $this->repository->update($updated);
                        $output = new RegisterNotificationRegistrationOutput($updated, false);
                    }

                    $event = $output->created ? 'push.registration.created' : 'push.registration.updated';
                    $attributes = [
                        'user_id' => $userId,
                        'registration_id' => $output->registration->id,
                        'platform' => $output->registration->destination->platform->value,
                        'generation' => $output->registration->generation,
                    ];
                    $this->transactionPort->afterCommit(function () use ($event, $attributes): void {
                        try {
                            $this->observabilityPort->emit($event, $attributes);
                        } catch (Throwable) {
                            return;
                        }
                    });

                    return $output;
                });
            } catch (NotificationRegistrationRaceException) {
                // PostgreSQL uniqueness races require a new transaction before rereading.
            }
        }

        throw new NotificationRegistrationConflictException;
    }
}
