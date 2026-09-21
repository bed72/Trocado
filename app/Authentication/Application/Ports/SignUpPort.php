<?php

declare(strict_types=1);

namespace App\Authentication\Application\Ports;

use SensitiveParameter;

interface SignUpPort
{
    public function create(string $name, string $email, #[SensitiveParameter] string $password): int;
}
