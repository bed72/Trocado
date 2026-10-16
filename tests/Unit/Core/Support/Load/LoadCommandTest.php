<?php

declare(strict_types=1);

use PHPUnit\Framework\Assert;
use Symfony\Component\Process\Process;

it('lists only the explicitly selected catalog without loading configuration or provisioning', function (): void {
    $root = dirname(__DIR__, 5);
    $process = new Process([PHP_BINARY, $root.'/tests/load.php', '--list', '--endpoint=/api/insights'], $root, [
        'DB_CONNECTION' => 'sqlite', 'DB_HOST' => 'invalid.invalid', 'DB_DATABASE' => 'operational',
        'TROCADO_LOAD_CONFIG' => '/missing/private-config.json',
    ]);
    $process->setTimeout(15);
    $process->run();

    expect($process->getExitCode())->toBe(0);
    $catalog = json_decode(trim($process->getOutput()), true, flags: JSON_THROW_ON_ERROR);
    expect($catalog)->toMatchArray(['scenario' => 'monthly-insights', 'endpoint' => '/api/insights'])
        ->and($process->getErrorOutput())->toBe('');
});

it('discovers one Load test with the dedicated Pest configuration without running its body', function (): void {
    $root = dirname(__DIR__, 5);
    $process = new Process([PHP_BINARY, $root.'/tests/load.php', '--list-tests', '--scenario=expense-pages'], $root, ['DB_HOST' => 'invalid.invalid']);
    $process->setTimeout(15);
    $process->run();

    expect($process->getExitCode())->toBe(0)
        ->and($process->getOutput())->toContain('ExpensePagesLoadTest');

    foreach (['MonthlyInsightsLoadTest', 'ExpenseMetricsLoadTest', 'ExpenseSuggestionsLoadTest', 'Tests\\Feature', 'Tests\\Unit', 'Blocked:'] as $unexpected) {
        Assert::assertStringNotContainsString($unexpected, $process->getOutput());
    }
});

it('rejects ambiguous or unsafe options without echoing their values', function (array $arguments): void {
    $root = dirname(__DIR__, 5);
    $process = new Process([PHP_BINARY, $root.'/tests/load.php', ...$arguments], $root);
    $process->setTimeout(15);
    $process->run();

    expect($process->getExitCode())->toBe(1)
        ->and($process->getErrorOutput())->toContain('Invalid Load selection')
        ->and($process->getOutput())->toBe('');

    Assert::assertStringNotContainsString('secret-sentinel', $process->getErrorOutput());
})->with([
    'missing explicit run selection' => [[]],
    'unknown option' => [['--token=secret-sentinel']],
    'URL CLI forbidden' => [['--url=https://secret-sentinel.example']],
    'unknown scenario' => [['--list', '--scenario=secret-sentinel']],
    'endpoint mismatch' => [['--list', '--scenario=expense-pages', '--endpoint=/api/insights']],
    'invalid objective' => [['--list', '--objective=secret-sentinel']],
    'duplicate selection' => [['--list', '--scenario=expense-pages', '--scenario=monthly-insights']],
    'ambiguous discovery' => [['--list', '--list-tests']],
]);

it('refuses a missing private configuration before starting HTTP or the engine', function (): void {
    $root = dirname(__DIR__, 5);
    $process = new Process([PHP_BINARY, $root.'/tests/load.php', '--scenario=expense-pages'], $root, [
        'TROCADO_LOAD_CONFIG' => '/missing/private-config.json', 'DB_HOST' => 'invalid.invalid',
    ]);
    $process->setTimeout(15);
    $process->run();

    expect($process->getExitCode())->toBe(2)
        ->and($process->getOutput())->toBe('')
        ->and($process->getErrorOutput())->toContain('Load refused');

    Assert::assertStringNotContainsString('/missing/private-config.json', $process->getErrorOutput());
});

it('keeps Load outside functional discovery without relying on a skip', function (): void {
    $root = dirname(__DIR__, 5);
    $process = new Process([PHP_BINARY, $root.'/tests/run.php', '--list-tests'], $root, [
        'DB_CONNECTION' => 'sqlite', 'DB_DATABASE' => 'operational', 'DB_HOST' => 'invalid.invalid',
    ]);
    $process->setTimeout(30);
    $process->run();

    expect($process->getExitCode())->toBe(0)
        ->and($process->getOutput())->toContain('Tests\\Unit', 'Tests\\Feature');

    foreach (['Tests\\Load', 'ExpensePagesLoadTest', 'incremental migrations ready'] as $unexpected) {
        Assert::assertStringNotContainsString($unexpected, $process->getOutput());
    }
});
