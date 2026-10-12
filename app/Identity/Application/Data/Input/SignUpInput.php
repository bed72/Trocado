<?php

declare(strict_types=1);

namespace App\Identity\Application\Data\Input;

use SensitiveParameter;

final readonly class SignUpInput
{
    public function __construct(
        public string $name,
        public string $email,
        #[SensitiveParameter] public string $password,
        public ?string $avatar = null,
    ) {}
}
