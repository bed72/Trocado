<?php

declare(strict_types=1);

namespace App\Authentication\Application\Data;

use DateTimeImmutable;
use SensitiveParameter;

final readonly class SignInOutput
{
    public function __construct(
        public int $id,
        public int $userId,
        #[SensitiveParameter]
        public string $plainTextToken,
        public DateTimeImmutable $expiresAt,
    ) {}
}
