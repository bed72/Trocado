<?php

declare(strict_types=1);

use App\Identity\Application\Data\Input\ResetPasswordInput;
use App\Identity\Application\Exceptions\CurrentPasswordException;
use App\Identity\Application\Exceptions\InvalidPasswordRecoveryException;
use App\Identity\Application\Ports\PasswordResetPort;
use App\Identity\Application\Repositories\PasswordRecoveryRepository;
use App\Identity\Application\UseCases\ResetPasswordUseCase;
use App\Identity\Domain\Exceptions\InvalidPasswordException;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\PasswordValueObject;
use Tests\Support\Core\Fakes\TransactionPortFake;
use Tests\Support\Core\Fixtures\UuidFixture;

it('coordinates the complete reset and schedules only owner and canonical email after commit', function (): void {
    $transactionPort = new TransactionPortFake;
    $port = $this->createMock(PasswordResetPort::class);
    $port->expects($this->once())->method('requestNotice')->with(UuidFixture::at(10), 'maria@example.com')
        ->willReturnCallback(function () use ($transactionPort): void {
            expect($transactionPort->isActive)->toBeFalse();
        });
    $repository = $this->createMock(PasswordRecoveryRepository::class);
    $repository->expects($this->once())->method('reset')->with(
        $this->callback(fn (EmailValueObject $email): bool => $email->value() === 'maria@example.com'),
        ' exact-token ',
        $this->callback(fn (PasswordValueObject $password): bool => $password->value() === ' Nova1 '),
    )->willReturnCallback(function () use ($transactionPort): string {
        expect($transactionPort->isActive)->toBeTrue();

        return UuidFixture::at(10);
    });

    expect((new ResetPasswordUseCase(transactionPort: $transactionPort, resetPort: $port, repository: $repository))->execute(
        new ResetPasswordInput(' MARIA@EXAMPLE.COM ', ' exact-token ', ' Nova1 '),
    ))->toBeNull()->and($transactionPort->trace)->toBe(['begin', 'register', 'commit']);
    $transactionPort->releaseAfterCommit();
});

it('propagates rejection or technical failure without scheduling a notice', function (RuntimeException $failure): void {
    $transactionPort = new TransactionPortFake;
    $port = $this->createMock(PasswordResetPort::class);
    $port->expects($this->never())->method('requestNotice');
    $repository = $this->createMock(PasswordRecoveryRepository::class);
    $repository->expects($this->once())->method('reset')->willThrowException($failure);

    try {
        (new ResetPasswordUseCase(transactionPort: $transactionPort, resetPort: $port, repository: $repository))->execute(new ResetPasswordInput('maria@example.com', 'token', 'Newpass1'));
        $this->fail('Expected the original failure.');
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($failure);
    }
    $transactionPort->releaseAfterCommit();
    expect($transactionPort->callbackCount)->toBe(0)->and($transactionPort->abortedFailures)->toBe([$failure]);
})->with([
    'invalid link' => fn () => new InvalidPasswordRecoveryException,
    'current password' => fn () => new CurrentPasswordException,
    'technical' => fn () => new RuntimeException('reset-sentinel'),
]);

it('rejects invalid password policy before opening a transaction', function (string $password): void {
    $transactionPort = new TransactionPortFake;
    $port = $this->createMock(PasswordResetPort::class);
    $port->expects($this->never())->method('requestNotice');
    $repository = $this->createMock(PasswordRecoveryRepository::class);
    $repository->expects($this->never())->method('reset');

    expect(fn () => (new ResetPasswordUseCase(transactionPort: $transactionPort, resetPort: $port, repository: $repository))->execute(
        new ResetPasswordInput('maria@example.com', 'token', $password),
    ))->toThrow(InvalidPasswordException::class);
    expect($transactionPort->commitCount)->toBe(0);
})->with(['short' => 'Abc1', 'long' => 'A1'.str_repeat('b', 31), 'bytes' => 'A1'.str_repeat('😀', 18), 'uppercase' => 'lowercase1', 'digit' => 'NoDigits']);
