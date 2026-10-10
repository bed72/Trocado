<?php

declare(strict_types=1);

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;
use Symfony\Component\Process\Process;

it('isolates two native parallel invocations with the same local tokens and independent cleanup', function (): void {
    $directory = tempnam(sys_get_temp_dir(), 'trocado-invocations-');
    unlink($directory);
    mkdir($directory, 0700);
    $root = dirname(__DIR__, 5);
    $processes = [];
    try {
        for ($index = 0; $index < 2; $index++) {
            $process = new Process([PHP_BINARY, $root.'/tests/run.php', 'tests/Feature/Core/Infrastructure/Isolation/Probes', '--parallel', '--processes=2', '--compact'], $root, [
                'DB_DATABASE' => 'trocado_testing', 'DB_URL' => '', 'TROCADO_TEST_PROBE_DIR' => $directory,
            ]);
            $process->setTimeout(45);
            $process->start();
            $processes[] = $process;
        }
        $deadline = microtime(true) + 30;
        do {
            $files = glob($directory.'/*.json');
            if (count($files) === 4) {
                break;
            }
            foreach ($processes as $process) {
                if (! $process->isRunning()) {
                    throw new RuntimeException('Invocation stopped before barrier: '.$process->getOutput().$process->getErrorOutput());
                }
            }
            usleep(10000);
        } while (microtime(true) < $deadline);
        expect($files)->toHaveCount(4);
        $reports = array_map(static fn (string $path): array => json_decode(file_get_contents($path), true, flags: JSON_THROW_ON_ERROR), $files);
        $runs = array_values(array_unique(array_column($reports, 'run')));
        expect($runs)->toHaveCount(2);
        foreach (['database', 'namespace', 'queue', 'log'] as $resource) {
            expect(array_unique(array_column($reports, $resource)))->toHaveCount(4);
        }
        foreach ($runs as $run) {
            $tokens = array_column(array_filter($reports, static fn (array $report): bool => $report['run'] === $run), 'token');
            sort($tokens);
            expect($tokens)->toBe(['1', '2']);
        }
        touch($directory.'/'.$runs[0].'.release');
        $first = str_contains($processes[0]->getOutput(), $runs[0]) ? $processes[0] : $processes[1];
        expect($first->wait())->toBe(0, $first->getOutput().$first->getErrorOutput());
        $second = $first === $processes[0] ? $processes[1] : $processes[0];
        expect($second->isRunning())->toBeTrue();
        foreach ($reports as $report) {
            if ($report['run'] === $runs[0]) {
                expect(is_file($report['log']))->toBeFalse();
                expect(DB::selectOne('select count(*) as count from pg_database where datname = ?', [$report['database']])->count)->toBe(0);
                expect(Redis::client()->rawCommand('EXISTS', $report['namespace'].'sentinel:1500', $report['namespace'].'queues:'.$report['queue']))->toBe(0);
            } else {
                expect(file_get_contents($report['log']))->toBe($report['database']);
                expect(Redis::client()->rawCommand('GET', $report['namespace'].'sentinel:1500'))->toBe($report['database'])
                    ->and(Redis::client()->rawCommand('LLEN', $report['namespace'].'queues:'.$report['queue']))->toBe(1);
            }
        }
        touch($directory.'/'.$runs[1].'.release');
        expect($second->wait())->toBe(0, $second->getOutput().$second->getErrorOutput());
        foreach ($reports as $report) {
            expect(is_file($report['log']))->toBeFalse()
                ->and(DB::selectOne('select count(*) as count from pg_database where datname = ?', [$report['database']])->count)->toBe(0);
            expect(Redis::client()->rawCommand('EXISTS', $report['namespace'].'sentinel:1500', $report['namespace'].'queues:'.$report['queue']))->toBe(0);
        }
    } finally {
        foreach (glob($directory.'/*.json') as $file) {
            $report = json_decode(file_get_contents($file), true, flags: JSON_THROW_ON_ERROR);
            touch($directory.'/'.$report['run'].'.release');
        }
        $cleanupFailure = null;
        foreach ($processes as $process) {
            try {
                if ($process->isRunning()) {
                    $process->wait();
                }
            } catch (Throwable $exception) {
                $process->stop(1);
                $cleanupFailure ??= $exception;
            }
        }
        foreach (glob($directory.'/*') as $file) {
            unlink($file);
        }
        rmdir($directory);
        if ($cleanupFailure !== null) {
            throw new RuntimeException('Invocation did not finish within its cleanup deadline.', previous: $cleanupFailure);
        }
    }
})->group('integration', 'redis', 'concurrency', 'parallel-isolation');
