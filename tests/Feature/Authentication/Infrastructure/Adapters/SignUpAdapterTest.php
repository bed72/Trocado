<?php

declare(strict_types=1);

use App\Authentication\Application\Exceptions\SignUpEmailAlreadyUsedException;
use App\Authentication\Application\Ports\SignUpPort;
use App\Authentication\Application\UseCases\SignUpUseCase;
use App\User\Infrastructure\Persistence\Models\UserModel;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

it('persists a canonical user with an adaptive password hash and no token', function (): void {
    $userId = app(SignUpUseCase::class)->execute(
        name: '  Maria Silva  ',
        password: ' Abc123 ',
        email: '  Maria.Silva@Example.COM  ',
    );

    $user = UserModel::query()->findOrFail($userId);

    expect($user->name)->toBe('Maria Silva')
        ->and($user->email)->toBe('maria.silva@example.com')
        ->and(Hash::check(' Abc123 ', $user->getAuthPassword()))->toBeTrue()
        ->and(Hash::check('Abc123', $user->getAuthPassword()))->toBeFalse()
        ->and($user->toArray())->not->toHaveKey('password');
    $this->assertDatabaseCount('personal_access_tokens', 0);
});

it('rejects a canonical duplicate without changing the existing password', function (): void {
    $existing = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'original password',
    ]);
    $originalHash = $existing->getAuthPassword();

    expect(fn (): int => app(SignUpUseCase::class)->execute(
        name: 'Outra Maria',
        email: ' MARIA@EXAMPLE.COM ',
        password: 'Outra123',
    ))->toThrow(SignUpEmailAlreadyUsedException::class);

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
            'name' => 'Concurrent winner',
            'email' => 'race@example.com',
            'password' => Hash::make('winner password'),
        ]);
    });

    expect(fn (): int => app(SignUpPort::class)->create(
        name: 'Concurrent loser',
        email: 'race@example.com',
        password: 'Perde123',
    ))->toThrow(SignUpEmailAlreadyUsedException::class);

    $this->assertDatabaseCount('users', 1);
    $this->assertDatabaseHas('users', [
        'name' => 'Concurrent winner',
        'email' => 'race@example.com',
    ]);
});
