<?php

declare(strict_types=1);

namespace App\Identity\Application\Data\Input;

final readonly class UpdateInput
{
    public function __construct(
        public ?string $name = null,
        public ?string $avatar = null,
        public bool $hasAvatar = false,
    ) {}
}
