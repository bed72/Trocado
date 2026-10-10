<?php

declare(strict_types=1);

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Application\UseCases\DeleteUserUseCase;
use Tests\Support\Core\Fakes\TransactionPortFake;
use Tests\Support\Core\Spies\ObservabilityPortSpy;
use Tests\Support\Core\Stubs\UserPortStub;

it('deletes an existing user inside the identity transaction', function (): void {
    $writePort = new TransactionPortFake;
    $observabilityPort = new ObservabilityPortSpy;
    $repository = $this->createMock(UserRepository::class);
    $userPort = new UserPortStub(identifier: 10);
    $repository->expects($this->once())->method('delete')->with(10)->willReturnCallback(function (int $id) use ($writePort): bool {
        expect($writePort->isActive)->toBeTrue();

        return true;
    });

    (new DeleteUserUseCase(userPort: $userPort, transactionPort: $writePort, observabilityPort: $observabilityPort, repository: $repository))->execute(id: 10);
    expect($writePort->commitCount)->toBe(1)->and($observabilityPort->events)->toBe([]);
    $writePort->releaseAfterCommit();
    expect($observabilityPort->events)->toBe([['event' => 'user.deleted', 'attributes' => ['user_id' => 10]]]);
});

it('fails inside the identity transaction when deleting an absent user', function (): void {
    $writePort = new TransactionPortFake;
    $observabilityPort = new ObservabilityPortSpy;
    $repository = $this->createMock(UserRepository::class);
    $userPort = new UserPortStub(identifier: 10);
    $repository->expects($this->once())->method('delete')->with(10)->willReturn(false);

    expect(fn () => (new DeleteUserUseCase(userPort: $userPort, transactionPort: $writePort, observabilityPort: $observabilityPort, repository: $repository))->execute(id: 10))
        ->toThrow(UserNotFoundException::class, 'User não encontrado.');
    $writePort->releaseAfterCommit();
    expect($writePort->commitCount)->toBe(1)->and($writePort->abortedFailures)->toHaveCount(1)
        ->and($writePort->committedResults)->toBe([])->and($observabilityPort->events)->toBe([]);
});

it('does not start a transaction or delete another user', function (): void {
    $writePort = $this->createMock(TransactionPort::class);
    $writePort->expects($this->never())->method('commit');
    $userPort = new UserPortStub(identifier: 20);
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->never())->method('delete');
    (new DeleteUserUseCase(userPort: $userPort, transactionPort: $writePort, observabilityPort: new ObservabilityPortSpy, repository: $repository))->execute(id: 10);
})->throws(UserNotFoundException::class);
