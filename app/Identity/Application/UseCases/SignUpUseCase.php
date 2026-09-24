<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;
use App\Identity\Domain\ValueObjects\PasswordValueObject;
use LogicException;
use SensitiveParameter;

final readonly class SignUpUseCase
{
    public function __construct(
        private TransactionPort $port,
        private UserRepository $repository,
    ) {}

    public function execute(string $name, string $email, #[SensitiveParameter] string $password): int
    {
        $user = new UserEntity(
            id: null,
            name: NameValueObject::fromString(value: $name),
            email: EmailValueObject::fromString(value: $email),
        );
        $validPassword = PasswordValueObject::fromString(value: $password);

        $registered = $this->port->execute(
            operation: fn (): UserEntity => $this->repository->create(
                user: $user,
                password: $validPassword->value(),
            ),
        );

        return $registered->id
            ?? throw new LogicException(message: 'O registro deve retornar uma identidade persistida.');
    }
}
