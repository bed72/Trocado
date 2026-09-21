<?php

declare(strict_types=1);

namespace App\Authentication\Infrastructure\Adapters;

use App\Authentication\Application\Exceptions\SignUpEmailAlreadyUsedException;
use App\Authentication\Application\Ports\SignUpPort;
use App\User\Domain\Entities\UserEntity;
use App\User\Domain\ValueObjects\EmailValueObject;
use App\User\Infrastructure\Persistence\Models\UserModel;
use Illuminate\Database\UniqueConstraintViolationException;
use RuntimeException;
use SensitiveParameter;
use Throwable;

final class SignUpAdapter implements SignUpPort
{
    public function create(string $name, string $email, #[SensitiveParameter] string $password): int
    {
        $user = new UserEntity(
            id: null,
            name: $name,
            email: EmailValueObject::fromString(value: $email),
        );

        if (UserModel::query()->where(column: 'email', operator: '=', value: $user->email->value())->exists()) {
            throw new SignUpEmailAlreadyUsedException;
        }

        try {
            $model = UserModel::query()->create([
                'name' => $user->name,
                'password' => $password,
                'email' => $user->email->value(),
            ]);
        } catch (UniqueConstraintViolationException) {
            throw new SignUpEmailAlreadyUsedException;
        } catch (Throwable) {
            throw new RuntimeException(message: 'Não foi possível persistir a nova conta.');
        }

        return (int) $model->getKey();
    }
}
