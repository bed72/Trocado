<?php

declare(strict_types=1);

namespace App\User\Infrastructure\Persistence\Repositories;

use App\User\Application\Exceptions\EmailAlreadyUsedException;
use App\User\Application\Repositories\UserRepository;
use App\User\Domain\Entities\UserEntity;
use App\User\Domain\ValueObjects\EmailValueObject;
use App\User\Infrastructure\Persistence\Models\UserModel;
use DateTimeImmutable;
use Illuminate\Database\UniqueConstraintViolationException;
use InvalidArgumentException;

final class EloquentUserRepository implements UserRepository
{
    public function create(UserEntity $user): UserEntity
    {
        if ($user->id !== null) {
            throw new InvalidArgumentException(message: 'A criação de User exige uma entidade ainda não persistida.');
        }

        try {
            $model = UserModel::query()->create([
                'name' => $user->name,
                'email' => $user->email->value(),
            ]);
        } catch (UniqueConstraintViolationException) {
            throw new EmailAlreadyUsedException(email: $user->email);
        }

        return $this->toEntity(model: $model);
    }

    public function update(UserEntity $user): ?UserEntity
    {
        if ($user->id === null) {
            throw new InvalidArgumentException(message: 'A atualização de User exige uma entidade persistida.');
        }

        $model = UserModel::query()->find(id: $user->id);

        if ($model === null) {
            return null;
        }

        try {
            $model->fill([
                'name' => $user->name,
                'email' => $user->email->value(),
            ])->save();
        } catch (UniqueConstraintViolationException) {
            throw new EmailAlreadyUsedException(email: $user->email);
        }

        return $this->toEntity(model: $model);
    }

    public function delete(int $id): bool
    {
        return UserModel::query()->whereKey(id: $id)->delete() > 0;
    }

    public function all(): array
    {
        return UserModel::query()->orderBy(column: 'id')->get()
            ->map(callback: fn (UserModel $model): UserEntity => $this->toEntity(model: $model))
            ->all();
    }

    public function findById(int $id): ?UserEntity
    {
        $model = UserModel::query()->find(id: $id);

        return $model === null ? null : $this->toEntity(model: $model);
    }

    public function findByEmail(EmailValueObject $email): ?UserEntity
    {
        $model = UserModel::query()->where(column: 'email', operator: '=', value: $email->value())->first();

        return $model === null ? null : $this->toEntity(model: $model);
    }

    private function toEntity(UserModel $model): UserEntity
    {
        return new UserEntity(
            id: (int) $model->getKey(),
            name: $model->name,
            email: EmailValueObject::fromString(value: $model->email),
            createdAt: $model->created_at === null ? null : DateTimeImmutable::createFromInterface(object: $model->created_at),
            updatedAt: $model->updated_at === null ? null : DateTimeImmutable::createFromInterface(object: $model->updated_at),
        );
    }
}
