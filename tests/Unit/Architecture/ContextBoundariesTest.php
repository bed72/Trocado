<?php

declare(strict_types=1);

$applicationPath = dirname(__DIR__, 3).'/app';
$contextDirectories = glob($applicationPath.'/*', GLOB_ONLYDIR) ?: [];
$contexts = array_map(basename(...), $contextDirectories);
sort($contexts);

$layers = ['Application', 'Domain', 'Infrastructure', 'Presentation'];

/** @var array<string, array<string, list<string>>> $allowedContextDependencies */
$allowedContextDependencies = [
    'Authentication' => [
        'Infrastructure' => ['App\\User'],
    ],
    'Budget' => [],
    'User' => [
        'Infrastructure' => ['Laravel\\Sanctum'],
    ],
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

it('keeps application data contracts immutable, constructor-only, and conventionally located', function () use ($applicationPath): void {
    $phpFiles = [];
    $collectPhpFiles = function (string $directory) use (&$collectPhpFiles, &$phpFiles): void {
        foreach (glob($directory.'/*') ?: [] as $entry) {
            if (is_dir($entry)) {
                $collectPhpFiles($entry);

                continue;
            }

            if (str_ends_with($entry, '.php')) {
                $phpFiles[] = $entry;
            }
        }
    };
    $collectPhpFiles($applicationPath);

    $dataFiles = array_values(array_filter(
        $phpFiles,
        fn (string $file): bool => str_contains($file, '/Application/Data/'),
    ));
    $misplacedDataContracts = array_values(array_filter(
        $phpFiles,
        fn (string $file): bool => preg_match('/(?:Input|Output)\.php$/', $file) === 1
            && ! str_contains($file, '/Application/Data/'),
    ));
    $applicationResults = array_values(array_filter(
        $phpFiles,
        fn (string $file): bool => str_contains($file, '/Application/') && str_ends_with($file, 'Result.php'),
    ));

    expect($dataFiles)->not->toBeEmpty()
        ->and($misplacedDataContracts)->toBe([])
        ->and($applicationResults)->toBe([]);

    foreach ($dataFiles as $file) {
        $relativeClass = substr($file, strlen($applicationPath) + 1, -4);
        $class = 'App\\'.str_replace('/', '\\', $relativeClass);
        $reflection = new ReflectionClass($class);
        $declaredMethods = array_values(array_filter(
            $reflection->getMethods(),
            fn (ReflectionMethod $method): bool => $method->getDeclaringClass()->getName() === $class
                && $method->getName() !== '__construct',
        ));

        expect(basename($file))->toMatch('/(?:Input|Output)\.php$/')
            ->and($reflection->isFinal())->toBeTrue()
            ->and($reflection->isReadOnly())->toBeTrue()
            ->and($reflection->getConstructor())->not->toBeNull()
            ->and($declaredMethods)->toBe([])
            ->and($reflection->getParentClass())->toBeFalse()
            ->and($reflection->getInterfaceNames())->toBe([]);

        foreach ($reflection->getProperties() as $property) {
            expect($property->hasType())->toBeTrue();
        }

        foreach ($reflection->getConstructor()?->getParameters() ?? [] as $parameter) {
            expect($parameter->hasType())->toBeTrue();
        }
    }
});

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
                    'Symfony\\Component\\HttpFoundation',
                    'response',
                    'route',
                ],
                $allowedContextDependencies[$context]['Presentation'] ?? [],
            ));
    }
}
