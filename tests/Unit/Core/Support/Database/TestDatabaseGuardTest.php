<?php

declare(strict_types=1);

use Tests\Support\Core\Database\TestDatabaseGuard;
use Tests\Support\Core\Database\TestDatabaseRun;

it('refuses unsafe configuration before identification or a destructive action', function (string $default, array $overrides): void {
    $run = TestDatabaseRun::create();
    $guard = new TestDatabaseGuard($run);
    $identified = false;
    $written = false;
    $config = array_replace(['driver' => 'pgsql', 'url' => null, 'database' => $run->database], $overrides);

    expect(function () use ($guard, $default, $config, &$identified, &$written): void {
        $guard->verify($default, $config, function () use (&$identified): array {
            $identified = true;

            return ['name' => 'trocado', 'owner' => null];
        });
        $written = true;
    })->toThrow(RuntimeException::class, 'Unsafe test database configuration');

    expect($identified)->toBeFalse()->and($written)->toBeFalse();
})->with([
    'SQLite default' => ['sqlite', []],
    'SQLite driver' => ['pgsql', ['driver' => 'sqlite']],
    'operational database' => ['pgsql', ['database' => 'trocado']],
    'old shared test database' => ['pgsql', ['database' => 'trocado_testing']],
    'similar unauthorized database' => ['pgsql', ['database' => 'trocado_testing_unregistered']],
    'operational URL' => ['pgsql', ['url' => 'postgresql://localhost/trocado']],
    'read routing' => ['pgsql', ['read' => ['database' => 'trocado']]],
    'write routing' => ['pgsql', ['write' => ['database' => 'trocado']]],
    'different schema' => ['pgsql', ['search_path' => 'operational']],
]);

it('refuses an effective database or ownership mismatch before a destructive action', function (bool $wrongDatabase, bool $wrongOwner): void {
    $run = TestDatabaseRun::create();
    $written = false;

    expect(function () use ($run, $wrongDatabase, $wrongOwner, &$written): void {
        (new TestDatabaseGuard($run))->verify('pgsql', [
            'driver' => 'pgsql', 'database' => $run->database, 'url' => '',
        ], fn (): array => [
            'name' => $wrongDatabase ? 'trocado' : $run->database,
            'owner' => $wrongOwner ? 'another-execution' : $run->marker(),
        ]);
        $written = true;
    })->toThrow(RuntimeException::class, 'Unsafe effective test connection');

    expect($written)->toBeFalse();
})->with(['effective database' => [true, false], 'ownership' => [false, true]]);

it('accepts only the exact registered database and execution owner', function (): void {
    $run = TestDatabaseRun::create();
    (new TestDatabaseGuard($run))->verify('pgsql', [
        'driver' => 'pgsql', 'database' => $run->database,
    ], fn (): array => ['name' => $run->database, 'owner' => $run->marker()]);

    expect($run->database)->toBe(TestDatabaseRun::BASE.'_'.$run->id)
        ->and(TestDatabaseRun::create()->database)->not->toBe($run->database);
});

it('rejects identifiers that could authorize another database or inject SQL', function (string $id, string $owner): void {
    expect(fn () => new TestDatabaseRun($id, $owner))->toThrow(RuntimeException::class, 'Invalid test execution identity');
})->with([
    'operational name' => ['trocado', str_repeat('a', 64)],
    'identifier injection' => ['"; drop database trocado', str_repeat('a', 64)],
    'missing owner' => [str_repeat('a', 24), ''],
]);
