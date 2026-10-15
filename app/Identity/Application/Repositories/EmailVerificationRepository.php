<?php

declare(strict_types=1);

namespace App\Identity\Application\Repositories;

use App\Identity\Application\Data\Output\EmailVerificationOutput;

interface EmailVerificationRepository
{
    public function verify(string $userId, string $hash): EmailVerificationOutput;
}
