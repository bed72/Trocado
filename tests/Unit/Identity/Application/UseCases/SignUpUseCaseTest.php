<?php

declare(strict_types=1);

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Ports\EmailVerificationPort;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Application\UseCases\SignUpUseCase;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\Exceptions\InvalidPasswordException;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;
use Tests\Support\Core\Fakes\TransactionPortFake;
use Tests\Support\Core\Spies\ObservabilityPortSpy;

it('registers the canonical identity inside the transaction and returns its identifier', function (): void {
    $persisted = new UserEntity(
        id: 10,
        name: NameValueObject::fromString(value: 'Maria'),
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    );
    $writePort = new TransactionPortFake;
    $observabilityPort = new ObservabilityPortSpy;
    $verificationRequests = [];
    $emailVerificationPort = $this->createMock(EmailVerificationPort::class);
    $emailVerificationPort->expects($this->once())->method('requestForRegistration')->with(10)
        ->willReturnCallback(function (int $userId) use ($writePort, $observabilityPort, &$verificationRequests): void {
            expect($writePort->isActive)->toBeFalse()
                ->and($observabilityPort->events)->toBe([['event' => 'user.registered', 'attributes' => ['user_id' => 10]]]);
            $verificationRequests[] = $userId;
        });
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())
        ->method('create')
        ->with(
            $this->callback(fn (UserEntity $user): bool => $user->id === null
                && $user->name->value() === 'Maria'
                && $user->email->value() === 'maria@example.com'),
            ' Abc123 ',
        )
        ->willReturnCallback(function (UserEntity $user, string $password) use ($writePort, $observabilityPort, $persisted): UserEntity {
            expect($writePort->isActive)->toBeTrue()->and($observabilityPort->events)->toBe([]);

            return $persisted;
        });

    $result = (new SignUpUseCase(
        transactionPort: $writePort,
        observabilityPort: $observabilityPort,
        emailPort: $emailVerificationPort,
        repository: $repository,
    ))->execute(
        name: ' Maria ',
        email: ' MARIA@EXAMPLE.COM ',
        password: ' Abc123 ',
    );

    expect($result)->toBe(10)
        ->and($writePort->commitCount)->toBe(1)
        ->and($writePort->committedResults)->toBe([$persisted])
        ->and($writePort->trace)->toBe(['begin', 'register', 'register', 'commit'])
        ->and($observabilityPort->events)->toBe([])
        ->and($verificationRequests)->toBe([]);

    $writePort->releaseAfterCommit();
    expect($verificationRequests)->toBe([10]);
});

it('rejects an invalid password before opening a transaction', function (): void {
    $writePort = $this->createMock(TransactionPort::class);
    $observabilityPort = new ObservabilityPortSpy;
    $emailVerificationPort = $this->createMock(EmailVerificationPort::class);
    $repository = $this->createMock(UserRepository::class);
    $writePort->expects($this->never())->method('commit');
    $emailVerificationPort->expects($this->never())->method('requestForRegistration');
    $repository->expects($this->never())->method('create');

    (new SignUpUseCase(
        transactionPort: $writePort,
        observabilityPort: $observabilityPort,
        emailPort: $emailVerificationPort,
        repository: $repository,
    ))->execute(
        name: 'Maria',
        email: 'maria@example.com',
        password: 'abc12',
    );
})->throws(InvalidPasswordException::class);

it('propagates a repository failure inside the unit without registration effects', function (): void {
    $transactionPort = new TransactionPortFake;
    $observabilityPort = new ObservabilityPortSpy;
    $sentinel = new RuntimeException('Registration write refused.');
    $emailPort = $this->createMock(EmailVerificationPort::class);
    $emailPort->expects($this->never())->method('requestForRegistration');
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('create')
        ->willReturnCallback(function () use ($transactionPort, $observabilityPort, $sentinel): never {
            expect($transactionPort->isActive)->toBeTrue()
                ->and($observabilityPort->events)->toBe([]);

            throw $sentinel;
        });
    $useCase = new SignUpUseCase(
        transactionPort: $transactionPort,
        observabilityPort: $observabilityPort,
        emailPort: $emailPort,
        repository: $repository,
    );

    try {
        $useCase->execute(name: 'Maria', email: 'maria@example.com', password: 'Correct1');
        $this->fail('The repository sentinel must propagate.');
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($sentinel);
    }

    $transactionPort->releaseAfterCommit();
    expect($transactionPort->trace)->toBe(['begin', 'abort'])
        ->and($transactionPort->abortedFailures)->toBe([$sentinel])
        ->and($transactionPort->committedResults)->toBe([])
        ->and($transactionPort->callbackCount)->toBe(0)
        ->and($transactionPort->isActive)->toBeFalse()
        ->and($observabilityPort->events)->toBe([]);
});
