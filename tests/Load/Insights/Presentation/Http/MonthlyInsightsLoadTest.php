<?php

declare(strict_types=1);

use Tests\Support\Core\Load\LoadConfiguration;
use Tests\Support\Core\Load\LoadHttpScenario;
use Tests\Support\Core\Load\LoadScenarioEnum;

it('measures monthly insights over external HTTP', function (): void {
    $configuration = LoadConfiguration::fromEnvironment();
    $summary = (new LoadHttpScenario($configuration))->run(LoadScenarioEnum::MonthlyInsights);
    fwrite(STDOUT, json_encode($summary, JSON_THROW_ON_ERROR).PHP_EOL);

    expect($summary['requests'])->toBeGreaterThan(0)
        ->and($summary['failureFraction'])->toBe(0.0);
    if ($configuration->p95ThresholdMs !== null) {
        expect($summary['p95Ms'])->toBeLessThanOrEqual($configuration->p95ThresholdMs);
    }
});
