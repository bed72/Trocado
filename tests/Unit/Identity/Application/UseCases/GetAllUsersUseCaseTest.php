<?php

declare(strict_types=1);

use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Application\UseCases\GetAllUsersUseCase;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;

it('returns every user supplied by the repository', function (): void {
    $users = [
        new UserEntity(id: 1, name: NameValueObject::fromString(value: 'Maria'), email: EmailValueObject::fromString(value: 'maria@example.com')),
        new UserEntity(id: 2, name: NameValueObject::fromString(value: 'João'), email: EmailValueObject::fromString(value: 'joao@example.com')),
    ];
    $repository = $this->createMock(UserRepository::class);
    $repository->expects($this->once())->method('all')->willReturn($users);

    expect((new GetAllUsersUseCase(repository: $repository))->execute())->toBe($users);
});
