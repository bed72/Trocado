<?php

declare(strict_types=1);

$applicationPath = dirname(__DIR__, 3).'/app';
$contextDirectories = glob($applicationPath.'/*', GLOB_ONLYDIR) ?: [];
$contexts = array_map(basename(...), $contextDirectories);
sort($contexts);

$layers = ['Application', 'Domain', 'Infrastructure', 'Presentation'];
$expectedContexts = ['Core', 'Expense', 'Identity'];

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

it('contains exactly the expected bounded contexts', function () use ($contexts, $expectedContexts): void {
    expect($contexts)->toBe($expectedContexts);
});

it('contains no source references to retired bounded contexts', function () use ($applicationPath): void {
    $retiredContexts = ['User', 'Authentication', 'Budget'];
    $staleReferences = [];

    $inspectDirectory = function (string $directory) use (&$inspectDirectory, &$staleReferences, $retiredContexts): void {
        foreach (glob($directory.'/*') ?: [] as $entry) {
            if (is_dir($entry)) {
                $inspectDirectory($entry);

                continue;
            }

            if (! str_ends_with($entry, '.php')) {
                continue;
            }

            $contents = file_get_contents($entry);

            foreach ($retiredContexts as $retiredContext) {
                $namespace = 'App'.'\\'.$retiredContext.'\\';

                if (is_string($contents) && str_contains($contents, $namespace)) {
                    $staleReferences[] = $entry;
                }
            }
        }
    };
    $inspectDirectory($applicationPath);

    expect(array_values(array_unique($staleReferences)))->toBe([]);
});

it('does not couple Eloquent models across bounded contexts', function () use ($applicationPath): void {
    $forbiddenReferences = [
        'App\\Expense\\Infrastructure\\Repositories\\Persistence\\Models\\ExpenseModel' => $applicationPath.'/Identity',
        'App\\Identity\\Infrastructure\\Repositories\\Persistence\\Models\\UserModel' => $applicationPath.'/Expense',
    ];

    foreach ($forbiddenReferences as $namespace => $contextPath) {
        $files = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($contextPath));

        foreach ($files as $file) {
            if (! $file->isFile() || $file->getExtension() !== 'php') {
                continue;
            }

            if (str_contains((string) file_get_contents($file->getPathname()), 'use '.$namespace.';')) {
                expect($file->getPathname())->toBeNull();
            }
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
            ->toOnlyUse([$contextNamespace.'\\Domain']);
    }

    if (is_dir($contextPath.'/Application')) {
        $applicationDependencies = [$contextNamespace.'\\Application', $contextNamespace.'\\Domain'];

        if ($context !== 'Core') {
            $applicationDependencies[] = 'App\\Core\\Application\\Ports\\TransactionPort';
        }

        if ($context === 'Expense') {
            $applicationDependencies[] = 'App\\Core\\Application\\Ports\\ObservabilityPort';
        }

        arch($context.' application depends only on its domain and own contracts')
            ->expect($contextNamespace.'\\Application')
            ->toOnlyUse($applicationDependencies);
    }

    if (is_dir($contextPath.'/Infrastructure')) {
        $infrastructureDependencies = [
            $contextNamespace.'\\Infrastructure',
            $contextNamespace.'\\Application',
            $contextNamespace.'\\Domain',
            'Illuminate',
        ];

        if ($context === 'Identity') {
            $infrastructureDependencies[] = 'Laravel\\Sanctum';
        }

        if ($context === 'Core') {
            $infrastructureDependencies[] = 'Monolog\\Formatter\\JsonFormatter';
            $infrastructureDependencies[] = 'Monolog\\LogRecord';
        }

        if ($context === 'Expense') {
            $infrastructureDependencies[] = 'Laravel\\Ai';
            $infrastructureDependencies[] = 'app';
            $infrastructureDependencies[] = 'config';
            $infrastructureDependencies[] = 'report';
        }

        arch($context.' infrastructure stays behind application boundaries')
            ->expect($contextNamespace.'\\Infrastructure')
            ->toOnlyUse($infrastructureDependencies);
    }

    if (is_dir($contextPath.'/Presentation')) {
        $presentationDependencies = [
            $contextNamespace.'\\Presentation',
            $contextNamespace.'\\Application',
            $contextNamespace.'\\Domain',
            'Illuminate',
            'Symfony\\Component\\HttpFoundation',
            'response',
            'route',
        ];

        arch($context.' presentation does not reach infrastructure')
            ->expect($contextNamespace.'\\Presentation')
            ->toOnlyUse($presentationDependencies);
    }
}
