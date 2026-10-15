<?php

declare(strict_types=1);

namespace Tests\Support\Core\Stubs;

use App\Core\Application\Ports\UserPort;

final readonly class UserPortStub implements UserPort
{
    public function __construct(private string $identifier, private string $accountStatus = 'active') {}

    public function id(): string
    {
        return $this->identifier;
    }

    public function status(): string
    {
        return $this->accountStatus;
    }
}
