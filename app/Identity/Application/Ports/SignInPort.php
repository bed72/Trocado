<?php

declare(strict_types=1);

namespace App\Identity\Application\Ports;

use App\Identity\Application\Data\SignInOutput;
use SensitiveParameter;

interface SignInPort
{
    public function issue(string $email, #[SensitiveParameter] string $password): SignInOutput;
}
