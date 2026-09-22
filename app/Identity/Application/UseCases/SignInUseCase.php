<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Identity\Application\Data\SignInOutput;
use App\Identity\Application\Ports\SignInPort;
use SensitiveParameter;

final readonly class SignInUseCase
{
    public function __construct(private SignInPort $port) {}

    public function execute(string $email, #[SensitiveParameter] string $password): SignInOutput
    {
        return $this->port->issue(email: $email, password: $password);
    }
}
