<?php

declare(strict_types=1);

use Illuminate\Cache\RateLimiter;
use Illuminate\Support\Facades\Cache;
use Tests\Support\Core\Fixtures\ConcurrentDatabaseProcess;

it('shares cache and limiter through independent process clients within one exclusive namespace', function (): void {
    $cache = Cache::store('redis');
    $limiter = new RateLimiter($cache);
    $cache->put('page:1500', 'parent', 60);
    $limiter->hit('quota:1500', 60);
    $child = new ConcurrentDatabaseProcess(static function (): void {
        $cache = Cache::store('redis');
        if ($cache->get('page:1500') !== 'parent') {
            throw new RuntimeException('Child cannot see the intentional shared cache namespace.');
        }
        $cache->put('page:1500', 'child', 60);
        (new RateLimiter($cache))->hit('quota:1500', 60);
    });
    try {
        $child->go();
        $child->done();
    } finally {
        $child->close();
    }
    expect($cache->get('page:1500'))->toBe('child')
        ->and((int) $limiter->attempts('quota:1500'))->toBe(2)
        ->and((int) $cache->get('quota:1500'))->toBe(2);
})->group('integration', 'redis', 'concurrency');
