<?php

declare(strict_types=1);

use Tests\Support\Core\Fixtures\LoadConfigurationFixture;
use Tests\Support\Core\Load\LoadConfiguration;

it('reads only documented configuration from a private file outside the repository', function (): void {
    $path = tempnam(sys_get_temp_dir(), 'trocado-load-config-');
    try {
        chmod($path, 0600);
        file_put_contents($path, json_encode([
            'version' => 1, 'targetUrl' => 'https://load.example', 'datasetId' => 'dataset-v1', 'profile' => 'capacity',
            'limits' => LoadConfigurationFixture::limits(),
        ], JSON_THROW_ON_ERROR));
        $configuration = LoadConfiguration::fromFile($path, dirname(__DIR__, 5));

        expect($configuration->targetUrl)->toBe('https://load.example')
            ->and($configuration->datasetId)->toBe('dataset-v1')
            ->and($configuration->profile)->toBe('capacity')
            ->and($configuration->limits['durationSeconds'])->toBe(30)
            ->and($configuration->limits['concurrency'])->toBe([1, 5, 10, 20]);

        chmod($path, 0644);
        expect(fn () => LoadConfiguration::fromFile($path, dirname(__DIR__, 5)))->toThrow(RuntimeException::class, 'private regular file');
    } finally {
        unlink($path);
    }
});

it('rejects credential-bearing URLs and invalid configuration without disclosing values', function (string $url, string $dataset, string $profile, array $limits): void {
    try {
        new LoadConfiguration($url, $dataset, $profile, array_replace(LoadConfigurationFixture::limits(), $limits));
        test()->fail('Invalid configuration was accepted.');
    } catch (InvalidArgumentException $exception) {
        expect($exception->getMessage())->not->toContain('secret-sentinel');
    }
})->with([
    'URL password' => ['https://user:secret-sentinel@load.example', 'v1', 'capacity', []],
    'URL query' => ['https://load.example?token=secret-sentinel', 'v1', 'capacity', []],
    'URL fragment' => ['https://load.example#secret-sentinel', 'v1', 'capacity', []],
    'non HTTP' => ['file:///secret-sentinel', 'v1', 'capacity', []],
    'not a base URL' => ['https://load.example/api/expenses', 'v1', 'capacity', []],
    'invalid dataset' => ['https://load.example', 'secret-sentinel/invalid', 'capacity', []],
    'invalid profile' => ['https://load.example', 'v1', 'secret-sentinel', []],
    'extra key' => ['https://load.example', 'v1', 'capacity', ['token' => 'secret-sentinel']],
    'negative timeout' => ['https://load.example', 'v1', 'capacity', ['requestTimeoutSeconds' => -1]],
    'string timeout' => ['https://load.example', 'v1', 'capacity', ['requestTimeoutSeconds' => '1']],
    'unbounded concurrency' => ['https://load.example', 'v1', 'capacity', ['concurrency' => [100]]],
    'duplicate concurrency' => ['https://load.example', 'v1', 'capacity', ['concurrency' => [1, 1]]],
    'non initial duration' => ['https://load.example', 'v1', 'capacity', ['durationSeconds' => 600]],
    'process bound' => ['https://load.example', 'v1', 'capacity', ['processTimeoutSeconds' => 20]],
    'campaign bound' => ['https://load.example', 'v1', 'capacity', ['campaignTimeoutSeconds' => 30]],
]);

it('refuses repository files and rejects secret fields or malformed JSON without echoing contents', function (): void {
    $root = dirname(__DIR__, 5);
    expect(fn () => LoadConfiguration::fromFile($root.'/composer.json', $root))->toThrow(RuntimeException::class, 'outside the repository');

    $path = tempnam(sys_get_temp_dir(), 'trocado-load-config-');
    try {
        chmod($path, 0600);
        foreach (['{"token":"secret-sentinel"}', '{"secret-sentinel":'] as $contents) {
            file_put_contents($path, $contents);
            try {
                LoadConfiguration::fromFile($path, $root);
                test()->fail('Invalid private file was accepted.');
            } catch (RuntimeException $exception) {
                expect($exception->getMessage())->not->toContain('secret-sentinel')
                    ->and($exception->getPrevious())->toBeNull();
            }
        }
    } finally {
        unlink($path);
    }
});
