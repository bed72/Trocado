<?php

declare(strict_types=1);

namespace Tests\Support\Identity\Fixtures;

use Illuminate\Support\Facades\Artisan;

final readonly class PasswordRecoveryWorkerFixture
{
    public function __construct(private string $queue) {}

    public function work(int $tries = 3): void
    {
        Artisan::call('queue:work', [
            'connection' => 'redis', '--queue' => $this->queue,
            '--once' => true, '--tries' => $tries, '--backoff' => 0, '--sleep' => 0,
        ]);
    }
}
