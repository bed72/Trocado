<?php

declare(strict_types=1);

namespace Tests\Support\Core\Fixtures;

final class LoadConfigurationFixture
{
    /** @return array{concurrency: list<int>, durationSeconds: int, warmupSeconds: int, requestTimeoutSeconds: int, processTimeoutSeconds: int, recoveryTimeoutSeconds: int, campaignTimeoutSeconds: int, maxRequests: int} */
    public static function limits(): array
    {
        return [
            'concurrency' => [1, 5, 10, 20],
            'durationSeconds' => 30,
            'warmupSeconds' => 1,
            'requestTimeoutSeconds' => 1,
            'processTimeoutSeconds' => 40,
            'recoveryTimeoutSeconds' => 5,
            'campaignTimeoutSeconds' => 300,
            'maxRequests' => 10,
        ];
    }
}
