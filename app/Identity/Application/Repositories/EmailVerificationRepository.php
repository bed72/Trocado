<?php

declare(strict_types=1);

namespace App\Identity\Application\Repositories;

use App\Identity\Application\Data\EmailVerificationOutput;

interface EmailVerificationRepository
{
    public function verify(int $userId, string $hash): EmailVerificationOutput;
}
