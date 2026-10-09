<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Domain\ValueObjects\NameValueObject;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use RuntimeException;

use function is_string;

final class UserSeeder extends Seeder
{
    public function run(): void
    {
        $password = $this->command?->secret('Senha para os dois usuários demonstrativos');

        if (! is_string($password) || $password === '') {
            throw new RuntimeException('Execute db:seed em modo interativo e informe a senha dos usuários demonstrativos.');
        }

        foreach ([
            ['name' => 'Gabriel Ramos', 'email' => 'developer.bed@gmail.com'],
            ['name' => 'Kelly Codolino', 'email' => 'kelly.cordolino@gmail.com'],
        ] as $attributes) {
            $user = UserModel::query()->firstOrNew(['email' => $attributes['email']]);
            $user->name = NameValueObject::fromString($attributes['name'])->value();
            $user->status = UserStatusEnum::Active;
            $user->email_verified_at ??= now();

            if (! $user->exists || ! Hash::check($password, $user->password)) {
                $user->password = $password;
            }

            $user->save();
        }
    }
}
