<?php

declare(strict_types=1);

namespace App\Identity\Application\Data\Input;

use SensitiveParameter;

final readonly class ResetPasswordInput
{
    public function __construct(
        public string $email,
        #[SensitiveParameter] public string $token,
        #[SensitiveParameter] public string $password,
    ) {}
}
