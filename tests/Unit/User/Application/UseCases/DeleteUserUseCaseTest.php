<?php

declare(strict_types=1);

use App\User\Application\Exceptions\UserNotFoundException;
use App\User\Application\Repositories\UserRepository;
use App\User\Application\UseCases\DeleteUserUseCase;

it('deletes an existing user', function (): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('delete')->with(10)->willReturn(true);

    (new DeleteUserUseCase(repository: $repository))->execute(id: 10);
});

it('fails when deleting an absent user', function (): void {
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('delete')->with(10)->willReturn(false);

    (new DeleteUserUseCase(repository: $repository))->execute(id: 10);
})->throws(UserNotFoundException::class, 'User 10 não encontrado.');
