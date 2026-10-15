<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\UserPort;
use App\Notifications\Application\Data\Input\RegisterNotificationRegistrationInput;
use App\Notifications\Application\Exceptions\NotificationRegistrationConflictException;
use App\Notifications\Application\Exceptions\NotificationRegistrationRaceException;
use App\Notifications\Application\Ports\NotificationPort;
use App\Notifications\Application\Repositories\NotificationRegistrationRepository;
use App\Notifications\Application\UseCases\CreateNotificationUseCase;
use App\Notifications\Domain\Entities\NotificationRegistrationEntity;
use App\Notifications\Domain\Enums\NotificationPlatformEnum;
use App\Notifications\Domain\ValueObjects\NotificationValueObject;
use Tests\Support\Core\Fakes\TransactionPortFake;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Notifications\Fixtures\NotificationRegistrationFixture;

it('revalidates session before repository access and only emits metadata after commit', function (): void {
    $transaction = new TransactionPortFake;
    $reference = new DateTimeImmutable('2026-10-13T12:00:00Z');
    $destination = new NotificationValueObject(installationId: NotificationRegistrationFixture::Installation, registrationKind: 'token', platform: NotificationPlatformEnum::Android, identifier: 'fake-token');
    $registration = new NotificationRegistrationEntity(id: NotificationRegistrationFixture::OtherInstallation, userId: UuidFixture::at(1), sessionId: UuidFixture::at(2), generation: 1, lastRegisteredAt: $reference, destination: $destination);
    $user = $this->createStub(UserPort::class);
    $user->method('id')->willReturn(UuidFixture::at(1));
    $sessionLocked = false;
    $recipient = $this->createMock(NotificationPort::class);
    $recipient->expects($this->once())->method('lock')->with(UuidFixture::at(1), $reference)->willReturnCallback(function () use ($transaction, &$sessionLocked): string {
        expect($transaction->isActive)->toBeTrue();
        $sessionLocked = true;

        return UuidFixture::at(2);
    });
    $repository = $this->createMock(NotificationRegistrationRepository::class);
    $repository->expects($this->once())->method('lock')->with($destination)->willReturnCallback(function () use ($transaction, &$sessionLocked): array {
        expect($transaction->isActive)->toBeTrue()->and($sessionLocked)->toBeTrue();

        return [];
    });
    $repository->expects($this->once())->method('create')->with(UuidFixture::at(1), UuidFixture::at(2), $destination, $reference)->willReturn($registration);
    $observability = $this->createMock(ObservabilityPort::class);
    $observability->expects($this->once())->method('emit')->with('push.registration.created', [
        'user_id' => UuidFixture::at(1), 'registration_id' => $registration->id, 'platform' => 'android', 'generation' => 1,
    ])->willReturnCallback(function () use ($transaction): void {
        expect($transaction->isActive)->toBeFalse();
    });
    $useCase = new CreateNotificationUseCase($user, $recipient, $transaction, $observability, $repository);
    $output = $useCase->execute(new RegisterNotificationRegistrationInput(registeredAt: $reference, destination: $destination));
    expect($output->created)->toBeTrue()->and($transaction->callbackCount)->toBe(1);
    $transaction->releaseAfterCommit();
});

it('rereads in a new transaction after a uniqueness race and preserves idempotency', function (): void {
    $transaction = new TransactionPortFake;
    $reference = new DateTimeImmutable('2026-10-13T12:00:00Z');
    $destination = new NotificationValueObject(installationId: NotificationRegistrationFixture::Installation, registrationKind: 'token', platform: NotificationPlatformEnum::Android, identifier: 'fake-token');
    $existing = new NotificationRegistrationEntity(id: NotificationRegistrationFixture::OtherInstallation, userId: UuidFixture::at(1), sessionId: UuidFixture::at(2), generation: 1, lastRegisteredAt: $reference, destination: $destination);
    $user = $this->createStub(UserPort::class);
    $user->method('id')->willReturn(UuidFixture::at(1));
    $recipient = $this->createMock(NotificationPort::class);
    $recipient->expects($this->exactly(2))->method('lock')->with(UuidFixture::at(1), $reference)->willReturn(UuidFixture::at(2));
    $repository = $this->createMock(NotificationRegistrationRepository::class);
    $repository->expects($this->exactly(2))->method('lock')->willReturnOnConsecutiveCalls([], [$existing]);
    $repository->expects($this->once())->method('create')->willThrowException(new NotificationRegistrationRaceException);
    $repository->expects($this->once())->method('update')->with($this->callback(fn (NotificationRegistrationEntity $value): bool => $value->id === $existing->id && $value->generation === 1));
    $useCase = new CreateNotificationUseCase($user, $recipient, $transaction, $this->createStub(ObservabilityPort::class), $repository);
    $output = $useCase->execute(new RegisterNotificationRegistrationInput(registeredAt: $reference, destination: $destination));

    expect($output->created)->toBeFalse()->and($output->registration->id)->toBe($existing->id)
        ->and($transaction->commitCount)->toBe(2)->and($transaction->abortedFailures)->toHaveCount(1);
});

it('bounds repeated transaction races without inventing success', function (): void {
    $transaction = new TransactionPortFake;
    $reference = new DateTimeImmutable('2026-10-13T12:00:00Z');
    $destination = new NotificationValueObject(installationId: NotificationRegistrationFixture::Installation, registrationKind: 'token', platform: NotificationPlatformEnum::Android, identifier: 'fake-token');
    $user = $this->createStub(UserPort::class);
    $user->method('id')->willReturn(UuidFixture::at(1));
    $recipient = $this->createStub(NotificationPort::class);
    $recipient->method('lock')->willReturn(UuidFixture::at(2));
    $repository = $this->createMock(NotificationRegistrationRepository::class);
    $repository->expects($this->exactly(3))->method('lock')->willThrowException(new NotificationRegistrationRaceException);
    $repository->expects($this->never())->method('create');
    $useCase = new CreateNotificationUseCase($user, $recipient, $transaction, $this->createStub(ObservabilityPort::class), $repository);

    expect(fn () => $useCase->execute(new RegisterNotificationRegistrationInput(registeredAt: $reference, destination: $destination)))->toThrow(NotificationRegistrationConflictException::class)
        ->and($transaction->commitCount)->toBe(3)->and($transaction->callbackCount)->toBe(0);
});
