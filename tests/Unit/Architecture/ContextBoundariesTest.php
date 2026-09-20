<?php

declare(strict_types=1);

$applicationPath = dirname(__DIR__, 3).'/app';
$contextDirectories = glob($applicationPath.'/*', GLOB_ONLYDIR) ?: [];
$contexts = array_map(basename(...), $contextDirectories);
sort($contexts);

$layers = ['Application', 'Domain', 'Infrastructure', 'Presentation'];

/** @var array<string, array<string, list<string>>> $allowedContextDependencies */
$allowedContextDependencies = [
    'Budget' => [],
];

it('organizes application code inside known bounded context layers', function () use ($contextDirectories, $layers): void {
    expect($contextDirectories)->not->toBeEmpty();

    foreach ($contextDirectories as $contextDirectory) {
        $entries = glob($contextDirectory.'/*') ?: [];
        $unexpectedEntries = array_values(array_filter(
            $entries,
            fn (string $entry): bool => is_file($entry) || ! in_array(basename($entry), $layers, true),
        ));

        expect($unexpectedEntries)->toBe([], sprintf(
            'O contexto %s contém arquivos ou diretórios fora das camadas permitidas.',
            basename($contextDirectory),
        ));
    }
});

it('references only existing contexts and layers in the dependency allowlist', function () use ($allowedContextDependencies, $contexts, $layers): void {
    foreach ($allowedContextDependencies as $context => $layerDependencies) {
        expect($contexts)->toContain($context);

        foreach (array_keys($layerDependencies) as $layer) {
            expect($layers)->toContain($layer);
        }
    }
});

arch('application code uses strict types and PSR-4 casing')
    ->expect('App')
    ->toUseStrictTypes()
    ->toBeCasedCorrectly();

foreach ($contexts as $context) {
    $contextPath = $applicationPath.'/'.$context;
    $contextNamespace = 'App\\'.$context;

    if (is_dir($contextPath.'/Domain')) {
        arch($context.' domain remains isolated and framework independent')
            ->expect($contextNamespace.'\\Domain')
            ->toOnlyUse(array_merge(
                [$contextNamespace.'\\Domain'],
                $allowedContextDependencies[$context]['Domain'] ?? [],
            ));
    }

    if (is_dir($contextPath.'/Application')) {
        arch($context.' application depends only on its domain and own contracts')
            ->expect($contextNamespace.'\\Application')
            ->toOnlyUse(array_merge(
                [$contextNamespace.'\\Application', $contextNamespace.'\\Domain'],
                $allowedContextDependencies[$context]['Application'] ?? [],
            ));
    }

    if (is_dir($contextPath.'/Infrastructure')) {
        arch($context.' infrastructure stays behind application boundaries')
            ->expect($contextNamespace.'\\Infrastructure')
            ->toOnlyUse(array_merge(
                [
                    $contextNamespace.'\\Infrastructure',
                    $contextNamespace.'\\Application',
                    $contextNamespace.'\\Domain',
                    'Illuminate',
                ],
                $allowedContextDependencies[$context]['Infrastructure'] ?? [],
            ));
    }

    if (is_dir($contextPath.'/Presentation')) {
        arch($context.' presentation does not reach infrastructure')
            ->expect($contextNamespace.'\\Presentation')
            ->toOnlyUse(array_merge(
                [
                    $contextNamespace.'\\Presentation',
                    $contextNamespace.'\\Application',
                    $contextNamespace.'\\Domain',
                    'Illuminate',
                    'response',
                    'route',
                ],
                $allowedContextDependencies[$context]['Presentation'] ?? [],
            ));
    }
}
