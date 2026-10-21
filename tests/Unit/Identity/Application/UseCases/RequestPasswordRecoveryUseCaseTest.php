<?php

declare(strict_types=1);

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Data\Output\PasswordRecoveryEmissionOutput;
use App\Identity\Application\Ports\PasswordRecoveryPort;
use App\Identity\Application\Repositories\PasswordRecoveryRepository;
use App\Identity\Application\UseCases\RequestPasswordRecoveryUseCase;
use App\Identity\Domain\Exceptions\InvalidEmailException;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use Tests\Support\Core\Fakes\TransactionPortFake;
use Tests\Support\Core\Fixtures\UuidFixture;

it('canonicalizes before persistence and requests the exact emitted credential only after commit', function (): void {
    $transactionPort = new TransactionPortFake;
    $recoveryPort = $this->createMock(PasswordRecoveryPort::class);
    $recoveryPort->expects($this->once())->method('isAvailable')->willReturn(true);
    $recoveryPort->expects($this->once())->method('requestLink')
        ->with(UuidFixture::at(10), 'maria@example.com', 'exact-test-token')
        ->willReturnCallback(function () use ($transactionPort): void {
            expect($transactionPort->isActive)->toBeFalse();
        });
    $repository = $this->createMock(PasswordRecoveryRepository::class);
    $repository->expects($this->once())->method('issue')
        ->with($this->callback(fn (EmailValueObject $email): bool => $email->value() === 'maria@example.com'))
        ->willReturnCallback(function () use ($transactionPort): PasswordRecoveryEmissionOutput {
            expect($transactionPort->isActive)->toBeTrue();

            return new PasswordRecoveryEmissionOutput(UuidFixture::at(10), 'exact-test-token');
        });

    $result = (new RequestPasswordRecoveryUseCase($transactionPort, $recoveryPort, $repository))->execute(' MARIA@EXAMPLE.COM ');

    expect($result)->toBeNull()
        ->and($transactionPort->trace)->toBe(['begin', 'register', 'commit'])
        ->and($transactionPort->callbackCount)->toBe(1);
    $transactionPort->releaseAfterCommit();
});

it('does not request delivery for an ineligible account or suppressed issuance', function (bool $suppressed): void {
    $transactionPort = new TransactionPortFake;
    $recoveryPort = $this->createMock(PasswordRecoveryPort::class);
    $recoveryPort->expects($this->once())->method('isAvailable')->willReturn(true);
    $recoveryPort->expects($this->never())->method('requestLink');
    $repository = $this->createMock(PasswordRecoveryRepository::class);
    $repository->expects($this->once())->method('issue')->willReturn(
        $suppressed ? new PasswordRecoveryEmissionOutput(UuidFixture::at(10), null) : null,
    );

    (new RequestPasswordRecoveryUseCase($transactionPort, $recoveryPort, $repository))->execute('maria@example.com');
    $transactionPort->releaseAfterCommit();
    expect($transactionPort->commitCount)->toBe(1)->and($transactionPort->callbackCount)->toBe(0);
})->with(['ineligible' => false, 'suppressed' => true]);

it('checks delivery availability before any account lookup or transaction', function (): void {
    $transactionPort = $this->createMock(TransactionPort::class);
    $transactionPort->expects($this->never())->method('commit');
    $recoveryPort = $this->createMock(PasswordRecoveryPort::class);
    $recoveryPort->expects($this->once())->method('isAvailable')->willReturn(false);
    $recoveryPort->expects($this->never())->method('requestLink');
    $repository = $this->createMock(PasswordRecoveryRepository::class);
    $repository->expects($this->never())->method('issue');

    expect((new RequestPasswordRecoveryUseCase($transactionPort, $recoveryPort, $repository))->execute('missing@example.com'))->toBeNull();
});

it('rejects malformed email without touching infrastructure', function (): void {
    $transactionPort = $this->createMock(TransactionPort::class);
    $transactionPort->expects($this->never())->method('commit');
    $recoveryPort = $this->createMock(PasswordRecoveryPort::class);
    $recoveryPort->expects($this->never())->method('isAvailable');
    $recoveryPort->expects($this->never())->method('requestLink');
    $repository = $this->createMock(PasswordRecoveryRepository::class);
    $repository->expects($this->never())->method('issue');

    (new RequestPasswordRecoveryUseCase($transactionPort, $recoveryPort, $repository))->execute('invalid');
})->throws(InvalidEmailException::class);

it('propagates a persistence failure without an after commit effect', function (): void {
    $transactionPort = new TransactionPortFake;
    $failure = new RuntimeException('emission-sentinel');
    $recoveryPort = $this->createMock(PasswordRecoveryPort::class);
    $recoveryPort->expects($this->once())->method('isAvailable')->willReturn(true);
    $recoveryPort->expects($this->never())->method('requestLink');
    $repository = $this->createMock(PasswordRecoveryRepository::class);
    $repository->expects($this->once())->method('issue')->willThrowException($failure);

    try {
        (new RequestPasswordRecoveryUseCase($transactionPort, $recoveryPort, $repository))->execute('maria@example.com');
        $this->fail('The sentinel must propagate.');
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($failure);
    }
    $transactionPort->releaseAfterCommit();
    expect($transactionPort->abortedFailures)->toBe([$failure])->and($transactionPort->callbackCount)->toBe(0);
});
