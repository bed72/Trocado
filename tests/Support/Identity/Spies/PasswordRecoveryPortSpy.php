<?php

declare(strict_types=1);

namespace Tests\Support\Identity\Spies;

use App\Identity\Application\Ports\PasswordRecoveryPort;
use SensitiveParameter;

final class PasswordRecoveryPortSpy implements PasswordRecoveryPort
{
    /** @var list<array{user_id: string, email: string, token: string}> */
    public array $links = [];

    public function __construct(public bool $available = true) {}

    public function isAvailable(): bool
    {
        return $this->available;
    }

    public function requestLink(string $userId, string $email, #[SensitiveParameter] string $token): void
    {
        $this->links[] = ['user_id' => $userId, 'email' => $email, 'token' => $token];
    }
}
