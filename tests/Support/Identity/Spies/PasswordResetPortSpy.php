<?php

declare(strict_types=1);

namespace Tests\Support\Identity\Spies;

use App\Identity\Application\Ports\PasswordResetPort;

final class PasswordResetPortSpy implements PasswordResetPort
{
    /** @var list<array{user_id: string, email: string}> */
    public array $notices = [];

    public function requestNotice(string $userId, string $email): void
    {
        $this->notices[] = ['user_id' => $userId, 'email' => $email];
    }
}
