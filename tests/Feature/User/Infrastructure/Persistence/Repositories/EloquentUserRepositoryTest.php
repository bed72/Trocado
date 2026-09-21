<?php

declare(strict_types=1);

use App\User\Application\Exceptions\EmailAlreadyUsedException;
use App\User\Domain\Entities\UserEntity;
use App\User\Domain\ValueObjects\EmailValueObject;
use App\User\Infrastructure\Persistence\Models\UserModel;
use App\User\Infrastructure\Persistence\Repositories\EloquentUserRepository;
use Illuminate\Contracts\Auth\Authenticatable;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\HasApiTokens;

it('persists and maps only the user identity fields', function (): void {
    $repository = new EloquentUserRepository;

    $persisted = $repository->create(user: new UserEntity(
        id: null,
        name: '  Maria Silva  ',
        email: EmailValueObject::fromString(value: ' Maria.Silva@Example.COM '),
    ));

    expect($persisted->id)->toBeInt()
        ->and($persisted->name)->toBe('Maria Silva')
        ->and($persisted->email->value())->toBe('maria.silva@example.com')
        ->and($persisted->createdAt)->toBeInstanceOf(DateTimeImmutable::class)
        ->and($persisted->updatedAt)->toBeInstanceOf(DateTimeImmutable::class)
        ->and(Schema::getColumnListing('users'))->toBe(['id', 'name', 'email', 'created_at', 'updated_at', 'password']);

    $this->assertDatabaseHas('users', [
        'id' => $persisted->id,
        'name' => 'Maria Silva',
        'email' => 'maria.silva@example.com',
    ]);
});

it('finds users by identifier and canonical email', function (): void {
    $model = UserModel::query()->create([
        'name' => 'Maria Silva',
        'email' => 'maria@example.com',
    ]);
    $repository = new EloquentUserRepository;

    $byId = $repository->findById(id: (int) $model->getKey());
    $byEmail = $repository->findByEmail(email: EmailValueObject::fromString(value: ' MARIA@EXAMPLE.COM '));

    expect($byId)->toBeInstanceOf(UserEntity::class)
        ->and($byId?->id)->toBe((int) $model->getKey())
        ->and($byEmail)->toBeInstanceOf(UserEntity::class)
        ->and($byEmail?->id)->toBe((int) $model->getKey())
        ->and($repository->findById(id: 99999))->toBeNull()
        ->and($repository->findByEmail(EmailValueObject::fromString(value: 'absent@example.com')))->toBeNull();
});

it('lists users in identifier order and returns an empty list when none exist', function (): void {
    $repository = new EloquentUserRepository;

    expect($repository->all())->toBe([]);

    $first = UserModel::query()->create(['name' => 'Maria', 'email' => 'maria@example.com']);
    $second = UserModel::query()->create(['name' => 'João', 'email' => 'joao@example.com']);

    $users = $repository->all();

    expect($users)->toHaveCount(2)
        ->and($users[0]->id)->toBe((int) $first->getKey())
        ->and($users[1]->id)->toBe((int) $second->getKey());
});

it('updates and maps an existing user', function (): void {
    $model = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
    ]);
    $repository = new EloquentUserRepository;

    $updated = $repository->update(user: new UserEntity(
        id: (int) $model->getKey(),
        name: 'Maria Souza',
        email: EmailValueObject::fromString(value: 'maria.souza@example.com'),
    ));

    expect($updated)->toBeInstanceOf(UserEntity::class)
        ->and($updated?->name)->toBe('Maria Souza')
        ->and($updated?->email->value())->toBe('maria.souza@example.com');
    $this->assertDatabaseHas('users', [
        'id' => $model->getKey(),
        'name' => 'Maria Souza',
        'email' => 'maria.souza@example.com',
    ]);
});

it('returns null when updating an absent user', function (): void {
    $updated = (new EloquentUserRepository)->update(user: new UserEntity(
        id: 99999,
        name: 'Maria',
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    ));

    expect($updated)->toBeNull();
});

it('translates an update uniqueness conflict into an application exception', function (): void {
    $maria = UserModel::query()->create(['name' => 'Maria', 'email' => 'maria@example.com']);
    UserModel::query()->create(['name' => 'João', 'email' => 'joao@example.com']);
    $repository = new EloquentUserRepository;

    $caughtException = null;

    try {
        $repository->update(user: new UserEntity(
            id: (int) $maria->getKey(),
            name: 'Maria',
            email: EmailValueObject::fromString(value: 'joao@example.com'),
        ));
    } catch (EmailAlreadyUsedException $exception) {
        $caughtException = $exception;
    }

    expect($caughtException)->toBeInstanceOf(EmailAlreadyUsedException::class)
        ->and($caughtException?->getMessage())->toBe('Não foi possível utilizar o e-mail informado.')
        ->and($caughtException?->getPrevious())->toBeNull();
    $this->assertDatabaseHas('users', [
        'id' => $maria->getKey(),
        'email' => 'maria@example.com',
    ]);
});

it('deletes an existing user and reports when it is absent', function (): void {
    $model = UserModel::query()->create(['name' => 'Maria', 'email' => 'maria@example.com']);
    $repository = new EloquentUserRepository;

    expect($repository->delete(id: (int) $model->getKey()))->toBeTrue()
        ->and($repository->delete(id: (int) $model->getKey()))->toBeFalse();
});

it('translates a database uniqueness conflict into an application exception', function (): void {
    $repository = new EloquentUserRepository;
    $repository->create(user: new UserEntity(
        id: null,
        name: 'Maria',
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    ));

    $caughtException = null;

    try {
        $repository->create(user: new UserEntity(
            id: null,
            name: 'Outra Maria',
            email: EmailValueObject::fromString(value: ' MARIA@EXAMPLE.COM '),
        ));
    } catch (EmailAlreadyUsedException $exception) {
        $caughtException = $exception;
    }

    expect($caughtException)->toBeInstanceOf(EmailAlreadyUsedException::class)
        ->and($caughtException?->getMessage())->toBe('Não foi possível utilizar o e-mail informado.')
        ->and($caughtException?->getPrevious())->toBeNull();
    $this->assertDatabaseCount('users', 1);
});

it('rejects creation for an entity that already has a persisted identity', function (): void {
    expect(fn (): UserEntity => (new EloquentUserRepository)->create(user: new UserEntity(
        id: 10,
        name: 'Maria',
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    )))->toThrow(InvalidArgumentException::class, 'A criação de User exige uma entidade ainda não persistida.');

    $this->assertDatabaseCount('users', 0);
});

it('rejects update for an entity without a persisted identity', function (): void {
    expect(fn (): ?UserEntity => (new EloquentUserRepository)->update(user: new UserEntity(
        id: null,
        name: 'Maria',
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    )))->toThrow(InvalidArgumentException::class, 'A atualização de User exige uma entidade persistida.');
});

it('uses the user model as the framework principal without exposing its password', function (): void {
    $model = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'secret-password',
    ]);

    expect($model)->toBeInstanceOf(Authenticatable::class)
        ->and(class_uses_recursive($model))->toHaveKey(HasApiTokens::class)
        ->and(Hash::check('secret-password', $model->password))->toBeTrue()
        ->and($model->toArray())->not->toHaveKey('password')
        ->and(config('auth.guards.web'))->toBe([
            'driver' => 'session',
            'provider' => 'users',
        ])
        ->and(config('auth.providers.users'))->toBe([
            'driver' => 'eloquent',
            'model' => UserModel::class,
        ])
        ->and(config('sanctum.expiration'))->toBe(120);
});
