<?php

declare(strict_types=1);

namespace App\Identity\Application\Data\Output;

use SensitiveParameter;

final readonly class PasswordRecoveryEmissionOutput
{
    public function __construct(public string $userId, #[SensitiveParameter] public ?string $token) {}
}
