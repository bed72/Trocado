<?php

declare(strict_types=1);

use App\User\Application\Repositories\UserRepository;
use App\User\Application\UseCases\GetAllUsersUseCase;
use App\User\Domain\Entities\UserEntity;
use App\User\Domain\ValueObjects\EmailValueObject;

it('returns every user supplied by the repository', function (): void {
    $users = [
        new UserEntity(id: 1, name: 'Maria', email: EmailValueObject::fromString(value: 'maria@example.com')),
        new UserEntity(id: 2, name: 'João', email: EmailValueObject::fromString(value: 'joao@example.com')),
    ];
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('all')->willReturn($users);

    expect((new GetAllUsersUseCase(repository: $repository))->execute())->toBe($users);
});
