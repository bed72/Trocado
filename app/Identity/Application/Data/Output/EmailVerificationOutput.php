<?php

declare(strict_types=1);

namespace App\Identity\Application\Data\Output;

final readonly class EmailVerificationOutput
{
    public function __construct(public bool $isValid, public bool $wasVerifiedNow) {}
}
