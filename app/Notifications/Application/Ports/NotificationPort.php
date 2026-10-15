<?php

declare(strict_types=1);

namespace App\Notifications\Application\Ports;

use DateTimeImmutable;

interface NotificationPort
{
    /** Revalidate and lock the current session inside the caller's transaction. */
    public function lock(string $userId, DateTimeImmutable $reference): string;
}
