<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Adapters;

use App\Identity\Application\Exceptions\EmailAlreadyUsedException;
use App\Identity\Application\Ports\CreatePort;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;
use App\Identity\Infrastructure\Persistence\Models\UserModel;
use DateTimeImmutable;
use DateTimeInterface;
use Illuminate\Database\UniqueConstraintViolationException;
use InvalidArgumentException;
use RuntimeException;
use SensitiveParameter;
use Throwable;
use UnexpectedValueException;

use function is_string;

final class RegistrationAdapter implements CreatePort
{
    public function create(UserEntity $user, #[SensitiveParameter] string $password): UserEntity
    {
        if ($user->id !== null) {
            throw new InvalidArgumentException(message: 'O registro exige uma identidade ainda não persistida.');
        }

        if (UserModel::query()->where(column: 'email', operator: '=', value: $user->email->value())->exists()) {
            throw new EmailAlreadyUsedException;
        }

        try {
            $model = UserModel::query()->create([
                'password' => $password,
                'name' => $user->name->value(),
                'email' => $user->email->value(),
            ]);
        } catch (UniqueConstraintViolationException) {
            throw new EmailAlreadyUsedException;
        } catch (Throwable) {
            throw new RuntimeException(message: 'Não foi possível persistir a nova conta.');
        }

        $name = $model->getAttribute(key: 'name');
        $email = $model->getAttribute(key: 'email');
        $createdAt = $model->getAttribute(key: 'created_at');
        $updatedAt = $model->getAttribute(key: 'updated_at');

        if (! is_string($name) || ! is_string($email)) {
            throw new UnexpectedValueException(message: 'A identidade persistida possui atributos inválidos.');
        }

        if (($createdAt !== null && ! $createdAt instanceof DateTimeInterface)
            || ($updatedAt !== null && ! $updatedAt instanceof DateTimeInterface)) {
            throw new UnexpectedValueException(message: 'A identidade persistida possui timestamps inválidos.');
        }

        return new UserEntity(
            id: (int) $model->getKey(),
            name: NameValueObject::fromString(value: $name),
            email: EmailValueObject::fromString(value: $email),
            createdAt: $createdAt === null ? null : DateTimeImmutable::createFromInterface(object: $createdAt),
            updatedAt: $updatedAt === null ? null : DateTimeImmutable::createFromInterface(object: $updatedAt),
        );
    }
}
