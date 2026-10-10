<?php

declare(strict_types=1);

use Symfony\Component\Process\Process;
use Tests\CreatesApplication;

it('refuses an unsafe inherited environment before provisioning', function (array $environment, string $diagnostic): void {
    $root = dirname(__DIR__, 5);
    $process = new Process([
        PHP_BINARY, $root.'/tests/run.php', 'tests/Feature/Core/Infrastructure/Database/TestDatabasePreflightTest.php', '--compact',
    ], $root, array_replace(['DB_CONNECTION' => 'pgsql', 'DB_DATABASE' => 'trocado_testing', 'DB_URL' => ''], $environment));
    $process->setTimeout(15);
    $process->run();

    expect($process->isSuccessful())->toBeFalse()
        ->and($process->getErrorOutput())->toContain($diagnostic)
        ->and($process->getOutput())->not->toContain('incremental migrations ready');
})->with([
    'SQLite' => [['DB_CONNECTION' => 'sqlite'], 'non-PostgreSQL'],
    'operational name' => [['DB_DATABASE' => 'trocado'], 'inherited database'],
    'similar name' => [['DB_DATABASE' => 'trocado_testing_unregistered'], 'inherited database'],
    'operational URL' => [['DB_URL' => 'postgresql://localhost/trocado'], 'refuses DB_URL'],
]);

it('runs pure unit files and lists feature tests without a database preflight', function (array $arguments): void {
    $root = dirname(__DIR__, 5);
    $process = new Process([PHP_BINARY, $root.'/tests/run.php', ...$arguments], $root, [
        'DB_CONNECTION' => 'sqlite', 'DB_DATABASE' => 'trocado', 'DB_HOST' => 'invalid.invalid',
        'DB_URL' => 'postgresql://invalid.invalid/trocado', 'TROCADO_TEST_MANIFEST' => false,
    ]);
    $process->setTimeout(15);
    $process->run();

    expect($process->isSuccessful())->toBeTrue()
        ->and($process->getOutput())->not->toContain('incremental migrations ready');
})->with([
    'unit file' => [['tests/Unit/Core/Support/Database/TestDatabaseGuardTest.php', '--compact']],
    'shared Core doubles without services' => [['tests/Unit/Core/Support/TransactionPortFakeTest.php', '--compact']],
    'Core Domain without services' => [['tests/Unit/Core/Domain', '--compact']],
    'Core adapters without services' => [['tests/Unit/Core/Infrastructure', '--compact']],
    'Identity Application without services' => [['tests/Unit/Identity/Application/UseCases', '--compact']],
    'feature discovery' => [['tests/Feature/Core/Infrastructure/Database/TestDatabasePreflightTest.php', '--list-tests']],
]);

it('refuses direct parallel lifecycle hooks without a manifest before an application is created', function (): void {
    $creator = new class
    {
        use CreatesApplication;
    };

    $previous = getenv('TROCADO_TEST_MANIFEST');
    putenv('TROCADO_TEST_MANIFEST');
    try {
        expect(fn () => $creator->createApplication())->toThrow(RuntimeException::class, 'Missing test preflight');
    } finally {
        if ($previous !== false) {
            putenv('TROCADO_TEST_MANIFEST='.$previous);
        }
    }
});
