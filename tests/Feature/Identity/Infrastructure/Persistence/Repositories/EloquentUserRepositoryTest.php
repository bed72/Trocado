<?php

declare(strict_types=1);

use App\Identity\Application\Exceptions\EmailAlreadyUsedException;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;
use App\Identity\Infrastructure\Persistence\Models\UserModel;
use App\Identity\Infrastructure\Persistence\Repositories\EloquentUserRepository;
use Illuminate\Contracts\Auth\Authenticatable;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\HasApiTokens;

it('finds users by identifier and canonical email', function (): void {
    $model = UserModel::query()->create([
        'password' => 'Abc123',
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

it('updates and maps an existing user', function (): void {
    $model = UserModel::query()->create([
        'name' => 'Maria',
        'password' => 'Abc123',
        'email' => 'maria@example.com',
    ]);
    $repository = new EloquentUserRepository;

    $updated = $repository->update(user: new UserEntity(
        id: (int) $model->getKey(),
        name: NameValueObject::fromString(value: 'Maria Souza'),
        email: EmailValueObject::fromString(value: 'maria.souza@example.com'),
    ));

    expect($updated)->toBeInstanceOf(UserEntity::class)
        ->and($updated?->name->value())->toBe('Maria Souza')
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
        name: NameValueObject::fromString(value: 'Maria'),
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    ));

    expect($updated)->toBeNull();
});

it('translates an update uniqueness conflict into an application exception', function (): void {
    $maria = UserModel::query()->create(['name' => 'Maria', 'email' => 'maria@example.com', 'password' => 'Abc123']);
    UserModel::query()->create(['name' => 'João', 'email' => 'joao@example.com', 'password' => 'Abc123']);
    $repository = new EloquentUserRepository;

    $caughtException = null;

    try {
        DB::transaction(fn () => $repository->update(user: new UserEntity(
            id: (int) $maria->getKey(),
            name: NameValueObject::fromString(value: 'Maria'),
            email: EmailValueObject::fromString(value: 'joao@example.com'),
        )));
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

it('deletes every token before the user and reports when the identity is absent', function (): void {
    $model = UserModel::query()->create([
        'name' => 'Maria',
        'password' => 'Abc123',
        'email' => 'maria@example.com',
    ]);
    $model->createToken(name: 'first');
    $model->createToken(name: 'second');
    $repository = new EloquentUserRepository;

    expect($repository->delete(id: (int) $model->getKey()))->toBeTrue()
        ->and($repository->delete(id: (int) $model->getKey()))->toBeFalse();

    $this->assertDatabaseCount('users', 0);
    $this->assertDatabaseCount('personal_access_tokens', 0);
});

it('rejects update for an entity without a persisted identity', function (): void {
    expect(fn (): ?UserEntity => (new EloquentUserRepository)->update(user: new UserEntity(
        id: null,
        name: NameValueObject::fromString(value: 'Maria'),
        email: EmailValueObject::fromString(value: 'maria@example.com'),
    )))->toThrow(InvalidArgumentException::class, 'A atualização de User exige uma entidade persistida.');
});

it('rejects model persistence without a password instead of inventing a credential', function (): void {
    expect(fn (): UserModel => DB::transaction(fn (): UserModel => UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
    ])))->toThrow(QueryException::class);

    $this->assertDatabaseCount('users', 0);
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
