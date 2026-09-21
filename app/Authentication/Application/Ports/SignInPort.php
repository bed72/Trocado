<?php

declare(strict_types=1);

namespace App\Authentication\Application\Ports;

use App\Authentication\Application\Data\SignInOutput;
use SensitiveParameter;

interface SignInPort
{
    public function issue(string $email, #[SensitiveParameter] string $password): SignInOutput;
}
