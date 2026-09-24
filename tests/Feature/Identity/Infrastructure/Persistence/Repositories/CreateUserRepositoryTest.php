<?php

declare(strict_types=1);

use App\Core\Application\Ports\TransactionPort;
use App\Identity\Application\Exceptions\EmailAlreadyUsedException;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Application\UseCases\SignUpUseCase;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;
use App\Identity\Infrastructure\Persistence\Models\UserModel;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

it('persists a canonical user with an adaptive password hash and no token', function (): void {
    $userId = app(SignUpUseCase::class)->execute(
        password: ' Abc123 ',
        name: '  Maria Silva  ',
        email: '  Maria.Silva@Example.COM  ',
    );

    $user = UserModel::query()->findOrFail($userId);

    expect($user->name)->toBe('Maria Silva')
        ->and($user->email)->toBe('maria.silva@example.com')
        ->and(Hash::check(' Abc123 ', $user->getAuthPassword()))->toBeTrue()
        ->and(Hash::check('Abc123', $user->getAuthPassword()))->toBeFalse()
        ->and($user->getAuthPassword())->not->toBe(' Abc123 ')
        ->and($user->toArray())->not->toHaveKey('password');
    $this->assertDatabaseCount('personal_access_tokens', 0);
});

it('rolls back registration when the surrounding identity operation fails', function (): void {
    $repository = app(UserRepository::class);
    $writePort = app(TransactionPort::class);

    expect(fn () => $writePort->execute(operation: function () use ($repository): never {
        $repository->create(
            password: 'Abc123',
            user: new UserEntity(
                id: null,
                name: NameValueObject::fromString(value: 'Maria'),
                email: EmailValueObject::fromString(value: 'maria@example.com'),
            ),
        );

        throw new RuntimeException('Falha após registrar a conta.');
    }))->toThrow(RuntimeException::class, 'Falha após registrar a conta.');

    $this->assertDatabaseCount('users', 0);
    $this->assertDatabaseCount('personal_access_tokens', 0);
});

it('rejects a canonical duplicate without changing the existing password', function (): void {
    $existing = UserModel::query()->create([
        'name' => 'Maria',
        'password' => 'Original123',
        'email' => 'maria@example.com',
    ]);
    $originalHash = $existing->getAuthPassword();

    expect(fn (): int => app(SignUpUseCase::class)->execute(
        name: 'Outra Maria',
        password: 'Outra123',
        email: ' MARIA@EXAMPLE.COM ',
    ))->toThrow(EmailAlreadyUsedException::class);

    expect($existing->fresh()->getAuthPassword())->toBe($originalHash);
    $this->assertDatabaseCount('users', 1);
    $this->assertDatabaseCount('personal_access_tokens', 0);
});

it('translates a unique constraint race to the same sign up conflict', function (): void {
    UserModel::creating(function (UserModel $user): void {
        if ($user->email !== 'race@example.com') {
            return;
        }

        DB::table('users')->insert([
            'created_at' => now(),
            'updated_at' => now(),
            'name' => 'Race Winner',
            'email' => 'race@example.com',
            'password' => Hash::make('winner password'),
        ]);
    });

    expect(fn (): UserEntity => app(UserRepository::class)->create(
        user: new UserEntity(
            id: null,
            name: NameValueObject::fromString(value: 'Race Loser'),
            email: EmailValueObject::fromString(value: 'race@example.com'),
        ),
        password: 'Perde123',
    ))->toThrow(EmailAlreadyUsedException::class);

    $this->assertDatabaseCount('users', 1);
    $this->assertDatabaseHas('users', [
        'name' => 'Race Winner',
        'email' => 'race@example.com',
    ]);
});
