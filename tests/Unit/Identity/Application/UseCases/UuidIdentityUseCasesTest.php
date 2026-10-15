<?php

declare(strict_types=1);

use App\Core\Application\Ports\TransactionPort;
use App\Core\Application\Ports\UserPort;
use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Identity\Application\Data\Input\UpdateInput;
use App\Identity\Application\Ports\EmailVerificationPort;
use App\Identity\Application\Repositories\EmailVerificationRepository;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Application\UseCases\DeleteUserUseCase;
use App\Identity\Application\UseCases\GetUserUseCase;
use App\Identity\Application\UseCases\UpdateUserUseCase;
use App\Identity\Application\UseCases\VerifyEmailUseCase;
use Tests\Support\Core\Spies\ObservabilityPortSpy;

it('rejects an invalid target before owner lookup transaction or repository access', function (string $operation, string $id): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->expects($this->never())->method('id');
    $transaction = $this->createMock(TransactionPort::class);
    $transaction->expects($this->never())->method('commit');
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->never())->method('getById');
    $repository->expects($this->never())->method('update');
    $repository->expects($this->never())->method('delete');
    $verification = $this->createMock(EmailVerificationRepository::class);
    $verification->expects($this->never())->method('verify');
    $events = $this->createMock(EmailVerificationPort::class);
    $events->expects($this->never())->method('publishVerified');
    $observer = new ObservabilityPortSpy;

    expect(fn () => match ($operation) {
        'get' => (new GetUserUseCase($userPort, $repository))->execute($id),
        'update' => (new UpdateUserUseCase($userPort, $observer, $repository))->execute($id, new UpdateInput(name: 'Maria')),
        'delete' => (new DeleteUserUseCase($userPort, $transaction, $observer, $repository))->execute($id),
        'verify' => (new VerifyEmailUseCase($transaction, $events, $verification))->execute($id, 'hash'),
    })->toThrow(InvalidUuidException::class);
    expect($observer->events)->toBe([]);
})->with(['get', 'update', 'delete', 'verify'])->with([
    'numeric' => '42', 'hash' => str_repeat('a', 64),
    'v4' => '017f22e2-79b0-4cc3-98c4-000000000001',
    'nil' => '00000000-0000-0000-0000-000000000000',
    'variant' => '017f22e2-79b0-7cc3-c8c4-000000000001',
    'whitespace' => ' 017f22e2-79b0-7cc3-98c4-000000000001 ',
]);
