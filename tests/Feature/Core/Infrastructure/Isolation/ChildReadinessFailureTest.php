<?php

declare(strict_types=1);

use Tests\Support\Core\Fixtures\ConcurrentDatabaseProcess;

it('reports a child guard failure before readiness and reaps it within the protocol deadline', function (): void {
    $manifest = getenv('TROCADO_TEST_MANIFEST');
    putenv('TROCADO_TEST_MANIFEST');
    try {
        expect(fn () => new ConcurrentDatabaseProcess(static function (): void {
            throw new RuntimeException('Operation must not be reached.');
        }))->toThrow(RuntimeException::class, 'Missing test preflight');
        expect(pcntl_waitpid(-1, $status, WNOHANG))->toBe(-1);
    } finally {
        putenv('TROCADO_TEST_MANIFEST='.$manifest);
    }
})->group('integration', 'concurrency');
