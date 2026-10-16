<?php

declare(strict_types=1);

use PHPUnit\Framework\Assert;
use Tests\Support\Core\Fixtures\LoadConfigurationFixture;
use Tests\Support\Core\Load\LoadConfiguration;
use Tests\Support\Core\Load\LoadManifest;
use Tests\Support\Core\Load\LoadScenarioEnum;

it('writes distinct private planned manifests without granting resource ownership or target readiness', function (): void {
    $root = dirname(__DIR__, 5);
    $configuration = new LoadConfiguration('https://load.example', 'dataset-v1', 'capacity', LoadConfigurationFixture::limits());
    $first = LoadManifest::plan(LoadScenarioEnum::ExpensePages, 'capacity', $configuration);
    $second = LoadManifest::plan(LoadScenarioEnum::MonthlyInsights, 'regression', $configuration);
    $paths = [];
    try {
        foreach ([$first, $second] as $manifest) {
            $paths[] = $path = $manifest->write($root);
            clearstatcache(true, $path);
            $document = json_decode(file_get_contents($path), true, flags: JSON_THROW_ON_ERROR);
            Assert::assertStringStartsNotWith($root.'/', $path);
            expect(fileperms($path) & 0777)->toBe(0600)
                ->and(fileperms(dirname($path)) & 0777)->toBe(0700)
                ->and($document)->toMatchArray([
                    'version' => 1, 'runId' => $manifest->runId, 'targetUrl' => 'https://load.example',
                    'datasetId' => 'dataset-v1', 'profile' => 'capacity', 'state' => 'Pending', 'phase' => 'preflight',
                    'targetVerification' => null, 'lease' => null, 'resources' => [],
                ]);
        }
        expect($first->runId)->not->toBe($second->runId)
            ->and($first->toArray()['owner'])->not->toBe($second->toArray()['owner'])
            ->and(fn () => $first->write($root))->toThrow(RuntimeException::class, 'Cannot allocate');
        expect(json_decode(file_get_contents($paths[0]), true, flags: JSON_THROW_ON_ERROR)['runId'])->toBe($first->runId);
    } finally {
        foreach ($paths as $path) {
            unlink($path);
            rmdir(dirname($path));
        }
    }
});
