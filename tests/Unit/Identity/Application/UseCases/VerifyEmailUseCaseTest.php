<?php

declare(strict_types=1);

use App\Identity\Application\Data\Output\EmailVerificationOutput;
use App\Identity\Application\Ports\EmailVerificationPort;
use App\Identity\Application\Repositories\EmailVerificationRepository;
use App\Identity\Application\UseCases\VerifyEmailUseCase;
use Tests\Support\Core\Fakes\TransactionPortFake;
use Tests\Support\Core\Fixtures\UuidFixture;

it('verifies inside the transaction and publishes only a new confirmation after commit', function (): void {
    $transaction = new TransactionPortFake;
    $published = [];
    $events = $this->createMock(EmailVerificationPort::class);
    $events->expects($this->once())->method('publishVerified')->with(UuidFixture::at(42))
        ->willReturnCallback(function (string $userId) use ($transaction, &$published): void {
            expect($transaction->isActive)->toBeFalse();
            $published[] = $userId;
        });
    $repository = $this->createMock(EmailVerificationRepository::class);
    $repository->expects($this->once())->method('verify')->with(UuidFixture::at(42), 'expected-hash')
        ->willReturnCallback(function () use ($transaction, &$published): EmailVerificationOutput {
            expect($transaction->isActive)->toBeTrue()->and($published)->toBe([]);

            return new EmailVerificationOutput(isValid: true, wasVerifiedNow: true);
        });

    $useCase = new VerifyEmailUseCase(transactionPort: $transaction, emailPort: $events, repository: $repository);

    expect($useCase->execute(strtoupper(UuidFixture::at(42)), 'expected-hash'))->toBeTrue()
        ->and($transaction->trace)->toBe(['begin', 'register', 'commit'])
        ->and($published)->toBe([]);

    $transaction->releaseAfterCommit();
    expect($published)->toBe([UuidFixture::at(42)]);
});

it('does not publish for invalid links or an already verified email', function (bool $isValid): void {
    $transaction = new TransactionPortFake;
    $events = $this->createMock(EmailVerificationPort::class);
    $events->expects($this->never())->method('publishVerified');
    $repository = $this->createMock(EmailVerificationRepository::class);
    $repository->expects($this->once())->method('verify')->with(UuidFixture::at(42), 'expected-hash')
        ->willReturn(new EmailVerificationOutput(isValid: $isValid, wasVerifiedNow: false));

    expect((new VerifyEmailUseCase($transaction, $events, $repository))->execute(UuidFixture::at(42), 'expected-hash'))->toBe($isValid)
        ->and($transaction->callbackCount)->toBe(0);
    $transaction->releaseAfterCommit();
})->with(['invalid' => false, 'already verified' => true]);

it('propagates the repository failure without publishing a confirmation', function (): void {
    $transaction = new TransactionPortFake;
    $events = $this->createMock(EmailVerificationPort::class);
    $events->expects($this->never())->method('publishVerified');
    $sentinel = new RuntimeException('Verification write failed.');
    $repository = $this->createMock(EmailVerificationRepository::class);
    $repository->expects($this->once())->method('verify')->with(UuidFixture::at(42), 'expected-hash')->willThrowException($sentinel);

    try {
        (new VerifyEmailUseCase($transaction, $events, $repository))->execute(UuidFixture::at(42), 'expected-hash');
        $this->fail('The repository sentinel must propagate.');
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($sentinel);
    }

    $transaction->releaseAfterCommit();
    expect($transaction->trace)->toBe(['begin', 'abort'])->and($transaction->callbackCount)->toBe(0);
});
