<?php

declare(strict_types=1);

use Dotenv\Dotenv;
use Illuminate\Contracts\Console\Kernel;
use Symfony\Component\Process\Process;
use Tests\Support\Core\Database\TestDatabasePreflight;
use Tests\Support\Core\Database\TestDatabaseRun;

require dirname(__DIR__).'/vendor/autoload.php';

$root = dirname(__DIR__);
$arguments = array_slice($argv, 1);
$app = null;
$manifest = null;
$preflight = null;
$prepared = [];
$temporaryDirectory = null;
$exitCode = 1;

try {
    $parallel = in_array('--parallel', $arguments, true) || in_array('-p', $arguments, true);
    $processes = 2;
    foreach ($arguments as $index => $argument) {
        if (array_any(['--recreate-databases', '--drop-databases', '--without-databases', '--no-test-tokens', '--tmp-dir', '--cache-directory'], static fn (string $option): bool => $argument === $option || str_starts_with($argument, $option.'='))) {
            throw new RuntimeException('Database lifecycle options are owned by the guarded preflight.');
        }
        if (str_starts_with($argument, '--processes=') || $argument === '--processes') {
            $value = $argument === '--processes' ? ($arguments[$index + 1] ?? '') : substr($argument, 12);
            if (preg_match('/\A[1-9][0-9]{0,2}\z/', $value) !== 1) {
                throw new RuntimeException('Use an explicit positive --processes count.');
            }
            $processes = (int) $value;
        }
    }
    if ($parallel && ! array_any($arguments, static fn (string $argument): bool => str_starts_with($argument, '--processes'))) {
        $arguments[] = '--processes=2';
    }

    $paths = array_values(array_filter($arguments, static fn (string $argument): bool => is_file($argument) || is_dir($argument)));
    $unitOnly = ($paths === [] && in_array('--testsuite=Unit', $arguments, true))
        || ($paths !== [] && array_all($paths, static fn (string $path): bool => realpath($path) === $root.'/tests/Unit' || str_starts_with(realpath($path), $root.'/tests/Unit/')));
    $listing = array_any($arguments, static fn (string $argument): bool => in_array($argument, ['--help', '-h', '--version', '--list-tests', '--list-tests-xml', '--list-groups', '--list-suites'], true));

    if (! $unitOnly && ! $listing) {
        if (is_file($root.'/bootstrap/cache/config.php')) {
            throw new RuntimeException('Clear cached configuration before testing: lerd artisan config:clear.');
        }

        if (($driver = getenv('DB_CONNECTION')) !== false && $driver !== 'pgsql') {
            throw new RuntimeException('Test preflight refuses non-PostgreSQL DB_CONNECTION.');
        }

        if (($name = getenv('DB_DATABASE')) !== false && $name !== TestDatabaseRun::BASE) {
            throw new RuntimeException('Test preflight refuses an inherited database other than the configured test base.');
        }

        Dotenv::createImmutable($root)->safeLoad();

        if (! in_array($_ENV['DB_URL'] ?? null, [null, ''], true)
            || ! in_array(getenv('DB_URL'), [false, ''], true)) {
            throw new RuntimeException('Test preflight refuses DB_URL.');
        }

        $xml = simplexml_load_file($root.'/phpunit.xml');

        foreach ($xml->php->env as $variable) {
            $key = (string) $variable['name'];
            $value = (string) $variable['value'];
            putenv($key.'='.$value);
            $_ENV[$key] = $_SERVER[$key] = $value;
        }

        $run = TestDatabaseRun::create($parallel ? $processes : 0);
        $manifest = $run->writeManifest();
        $temporaryDirectory = sys_get_temp_dir().'/trocado-run-'.$run->id;
        if (! mkdir($temporaryDirectory, 0700)) {
            throw new RuntimeException('Cannot allocate runner resource directory.');
        }
        mkdir($temporaryDirectory.'/cache', 0700);
        mkdir($temporaryDirectory.'/views', 0700);
        $arguments[] = '--cache-directory='.$temporaryDirectory.'/cache';
        if ($parallel) {
            $arguments[] = '--tmp-dir='.$temporaryDirectory;
        }

        foreach (['DB_DATABASE' => $run->database, 'TROCADO_TEST_MANIFEST' => $manifest, 'TROCADO_TEST_RUN_ID' => $run->id, 'VIEW_COMPILED_PATH' => $temporaryDirectory.'/views'] as $key => $value) {
            putenv($key.'='.$value);
            $_ENV[$key] = $_SERVER[$key] = $value;
        }

        $app = require $root.'/bootstrap/app.php';
        $app->make(Kernel::class)->bootstrap();
        $preflight = new TestDatabasePreflight($run);
        $prepared[] = $preflight;
        $preflight->provision($app);
        $preflight->migrate($app);
        foreach ($run->tokens as $token) {
            $processRun = $run->forToken($token);
            $app['db']->purge('pgsql');
            $app['config']->set('database.connections.pgsql.database', $processRun->database);
            $processPreflight = new TestDatabasePreflight($processRun);
            $prepared[] = $processPreflight;
            $processPreflight->provision($app);
            $processPreflight->migrate($app);
        }
        $app['db']->purge('pgsql');
        $app['config']->set('database.connections.pgsql.database', $run->database);
        fwrite(STDOUT, 'Test preflight: '.$run->database.' (incremental migrations ready)'.PHP_EOL);
        $app->make('db')->disconnect('pgsql');
    }

    $process = new Process([PHP_BINARY, $root.'/vendor/bin/pest', ...$arguments], $root, ['TEST_TOKEN' => false, 'UNIQUE_TEST_TOKEN' => false]);
    $process->setTimeout(null);
    $exitCode = $process->run(static function (string $type, string $buffer): void {
        fwrite($type === Process::ERR ? STDERR : STDOUT, $buffer);
    });
} catch (Throwable $exception) {
    fwrite(STDERR, 'Test preflight failed: '.$exception->getMessage().PHP_EOL);
} finally {
    try {
        if ($app !== null && $preflight !== null) {
            foreach (array_reverse($prepared) as $item) {
                $item->cleanupOwned($app);
            }
        }

        if ($manifest !== null) {
            unlink($manifest);
        }
        if ($temporaryDirectory !== null && is_dir($temporaryDirectory)) {
            $entries = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($temporaryDirectory, FilesystemIterator::SKIP_DOTS), RecursiveIteratorIterator::CHILD_FIRST);
            foreach ($entries as $entry) {
                $entry->isDir() ? rmdir($entry->getPathname()) : unlink($entry->getPathname());
            }
            rmdir($temporaryDirectory);
        }
    } catch (Throwable $exception) {
        fwrite(STDERR, 'Test cleanup failed: '.$exception->getMessage().PHP_EOL);
        $exitCode = 1;
    }
}

exit($exitCode);
