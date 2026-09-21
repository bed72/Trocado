<?php

declare(strict_types=1);

use App\Authentication\Application\Ports\AuthenticationWritePort;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

it('rolls back the complete authentication write operation on failure', function (): void {
    $port = app(AuthenticationWritePort::class);

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
