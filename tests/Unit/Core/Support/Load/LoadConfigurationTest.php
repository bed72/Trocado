<?php

declare(strict_types=1);

use PHPUnit\Framework\Assert;
use Tests\Support\Core\Load\LoadConfiguration;

it('reads bounded load settings and a token only from a private confirmed target file', function (): void {
    $path = tempnam(sys_get_temp_dir(), 'trocado-load-config-');
    try {
        chmod($path, 0600);
        file_put_contents($path, json_encode([
            'version' => 1, 'dedicatedTarget' => true, 'targetUrl' => 'https://load.test',
            'token' => 'secret-sentinel', 'concurrency' => 5, 'durationSeconds' => 10, 'p95ThresholdMs' => 200,
        ], JSON_THROW_ON_ERROR));
        $configuration = LoadConfiguration::fromFile($path, dirname(__DIR__, 5));
        expect($configuration->targetUrl)->toBe('https://load.test')
            ->and($configuration->concurrency)->toBe(5)
            ->and($configuration->durationSeconds)->toBe(10)
            ->and($configuration->p95ThresholdMs)->toBe(200.0)
            ->and($configuration->headers())->toBe(['Authorization' => 'Bearer secret-sentinel', 'Accept' => 'application/vnd.api+json'])
            ->and($configuration->redact('Bearer secret-sentinel'))->toBe('Bearer [redacted]');

        chmod($path, 0644);
        expect(fn () => LoadConfiguration::fromFile($path, dirname(__DIR__, 5)))->toThrow(RuntimeException::class, 'private regular file');
    } finally {
        unlink($path);
    }
});

it('rejects unsafe URLs secrets and unbounded or invalid load settings', function (string $url, string $token, int $concurrency, int $duration, ?float $p95): void {
    try {
        new LoadConfiguration($url, $token, $concurrency, $duration, $p95);
        test()->fail('Invalid configuration was accepted.');
    } catch (InvalidArgumentException $exception) {
        Assert::assertStringNotContainsString('secret-sentinel', $exception->getMessage());
    }
})->with([
    'URL password' => ['https://user:secret-sentinel@load.test', 'test-token', 1, 5, null],
    'URL query' => ['https://load.test?token=secret-sentinel', 'test-token', 1, 5, null],
    'URL fragment' => ['https://load.test#secret-sentinel', 'test-token', 1, 5, null],
    'remote host' => ['https://production.example', 'test-token', 1, 5, null],
    'non HTTP' => ['file:///secret-sentinel', 'test-token', 1, 5, null],
    'endpoint as base' => ['https://load.test/api/expenses', 'test-token', 1, 5, null],
    'invalid token' => ['https://load.test', "secret-sentinel\r\nInjected: true", 1, 5, null],
    'zero concurrency' => ['https://load.test', 'test-token', 0, 5, null],
    'excess concurrency' => ['https://load.test', 'test-token', 21, 5, null],
    'zero duration' => ['https://load.test', 'test-token', 1, 0, null],
    'excess duration' => ['https://load.test', 'test-token', 1, 31, null],
    'negative threshold' => ['https://load.test', 'test-token', 1, 5, -1],
    'infinite threshold' => ['https://load.test', 'test-token', 1, 5, INF],
]);

it('keeps short defaults and requires opt in without loading the application', function (): void {
    $configuration = new LoadConfiguration('https://load.test', 'test-token');
    expect($configuration->concurrency)->toBe(1)
        ->and($configuration->durationSeconds)->toBe(5)
        ->and($configuration->p95ThresholdMs)->toBeNull();
    $previous = getenv('TROCADO_LOAD_RUN');
    putenv('TROCADO_LOAD_RUN');
    try {
        expect(LoadConfiguration::fromEnvironment(...))->toThrow(RuntimeException::class, 'composer test:load');
    } finally {
        if ($previous !== false) {
            putenv("TROCADO_LOAD_RUN={$previous}");
        }
    }
});

it('refuses repository files malformed JSON unknown fields and unconfirmed targets without disclosing contents', function (): void {
    $root = dirname(__DIR__, 5);
    expect(fn () => LoadConfiguration::fromFile($root.'/composer.json', $root))->toThrow(RuntimeException::class, 'outside the repository');
    $path = tempnam(sys_get_temp_dir(), 'trocado-load-config-');
    try {
        chmod($path, 0600);
        $valid = ['version' => 1, 'targetUrl' => 'https://load.test', 'token' => 'secret-sentinel', 'dedicatedTarget' => true];
        foreach (['{"secret-sentinel":', json_encode(array_replace($valid, ['dedicatedTarget' => false])), json_encode($valid + ['unknown' => 'secret-sentinel']), json_encode($valid + ['durationSeconds' => '5'])] as $contents) {
            file_put_contents($path, $contents);
            try {
                LoadConfiguration::fromFile($path, $root);
                test()->fail('Invalid private file was accepted.');
            } catch (RuntimeException $exception) {
                Assert::assertStringNotContainsString('secret-sentinel', $exception->getMessage());
                expect($exception->getPrevious())->toBeNull();
            }
        }
    } finally {
        unlink($path);
    }
});
