<?php

declare(strict_types=1);

use App\Identity\Application\Ports\IdentityWritePort;
use App\Identity\Infrastructure\Persistence\Models\UserModel;
use App\Identity\Infrastructure\Persistence\Repositories\EloquentIdentityRepository;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

it('rolls back the complete identity write operation on failure', function (): void {
    $port = app(IdentityWritePort::class);

    expect(fn () => $port->execute(operation: function (): never {
        DB::table('users')->insert([
            'name' => 'Maria',
            'created_at' => now(),
            'updated_at' => now(),
            'email' => 'maria@example.com',
            'password' => Hash::make('password'),
        ]);

        throw new RuntimeException('Falha após a escrita.');
    }))->toThrow(RuntimeException::class, 'Falha após a escrita.');

    $this->assertDatabaseCount('users', 0);
});

it('restores the user and every token when account deletion fails', function (): void {
    $user = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Abc123',
    ]);
    $user->createToken(name: 'first');
    $user->createToken(name: 'second');
    $repository = new EloquentIdentityRepository;
    $port = app(IdentityWritePort::class);

    expect(fn () => $port->execute(operation: function () use ($repository, $user): never {
        expect($repository->delete(id: (int) $user->getKey()))->toBeTrue();

        throw new RuntimeException('Falha após remover a conta.');
    }))->toThrow(RuntimeException::class, 'Falha após remover a conta.');

    $this->assertDatabaseHas('users', ['id' => $user->getKey()]);
    $this->assertDatabaseCount('personal_access_tokens', 2);
});
