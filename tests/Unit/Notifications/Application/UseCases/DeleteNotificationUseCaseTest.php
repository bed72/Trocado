<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\UserPort;
use App\Notifications\Application\Exceptions\NotificationRegistrationNotFoundException;
use App\Notifications\Application\Ports\NotificationPort;
use App\Notifications\Application\Repositories\NotificationRegistrationRepository;
use App\Notifications\Application\UseCases\DeleteNotificationUseCase;
use Tests\Support\Core\Fakes\TransactionPortFake;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Notifications\Fixtures\NotificationRegistrationFixture;

it('canonicalizes the registration before scoped deletion and emits its identity only after commit', function (): void {
    $reference = new DateTimeImmutable('2026-10-13T12:00:00Z');
    $transaction = new TransactionPortFake;
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
    $repository->expects($this->once())->method('delete')->with(UuidFixture::at(1), NotificationRegistrationFixture::Registration)->willReturnCallback(function () use ($transaction, &$sessionLocked): bool {
        expect($transaction->isActive)->toBeTrue()->and($sessionLocked)->toBeTrue();

        return true;
    });
    $observability = $this->createMock(ObservabilityPort::class);
    $observability->expects($this->once())->method('emit')->with('push.registration.deleted', [
        'user_id' => UuidFixture::at(1), 'registration_id' => NotificationRegistrationFixture::Registration,
    ])->willReturnCallback(function () use ($transaction): void {
        expect($transaction->isActive)->toBeFalse();
    });

    (new DeleteNotificationUseCase($user, $recipient, $transaction, $observability, $repository))
        ->execute(strtoupper(NotificationRegistrationFixture::Registration), $reference);
    expect($transaction->callbackCount)->toBe(1);
    $transaction->releaseAfterCommit();
});

it('rejects invalid identities outside HTTP before session locks or repository access', function (string $id): void {
    $transaction = new TransactionPortFake;
    $user = $this->createStub(UserPort::class);
    $user->method('id')->willReturn(UuidFixture::at(1));
    $recipient = $this->createMock(NotificationPort::class);
    $recipient->expects($this->never())->method('lock');
    $repository = $this->createMock(NotificationRegistrationRepository::class);
    $repository->expects($this->never())->method('delete');
    $observability = $this->createMock(ObservabilityPort::class);
    $observability->expects($this->never())->method('emit');
    $useCase = new DeleteNotificationUseCase($user, $recipient, $transaction, $observability, $repository);

    expect(fn () => $useCase->execute($id, new DateTimeImmutable('2026-10-13T12:00:00Z')))
        ->toThrow(NotificationRegistrationNotFoundException::class)
        ->and($transaction->commitCount)->toBe(0)->and($transaction->callbackCount)->toBe(0);
})->with(['42', '017f22e2-79b0-4cc3-98c4-000000000201', '017f22e2-79b0-7cc3-c8c4-000000000201', ' '.NotificationRegistrationFixture::Registration]);
