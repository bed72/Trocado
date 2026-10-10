<?php

declare(strict_types=1);

namespace Tests\Support\Core\Fixtures;

use Illuminate\Support\Facades\Log;
use RuntimeException;
use Tests\Support\Core\Database\TestDatabaseRun;

final readonly class ObservabilityLogFixture
{
    public string $path;

    private string $previousStream;

    public function __construct()
    {
        $run = TestDatabaseRun::fromEnvironment();
        $path = tempnam(sys_get_temp_dir(), 'trocado-observability-'.$run->id.'-'.($run->token ?? 'serial').'-');

        if ($path === false) {
            throw new RuntimeException('Could not allocate the test log.');
        }

        $this->path = $path;
        $this->previousStream = config('logging.channels.observability_stderr.handler_with.stream');
        config()->set('logging.channels.observability_stderr.handler_with.stream', $path);
        $this->forgetChannels();
    }

    /** @return list<array<string, mixed>> */
    public function records(): array
    {
        $lines = file($this->path, FILE_IGNORE_NEW_LINES);

        if ($lines === false) {
            throw new RuntimeException('Could not read the test log.');
        }

        return array_map(static fn (string $line): array => json_decode($line, true, flags: JSON_THROW_ON_ERROR), $lines);
    }

    public function failDestination(): void
    {
        config()->set('logging.channels.observability_stderr.handler_with.stream', $this->path.'/output.log');
        $this->forgetChannels();
    }

    public function close(): void
    {
        $this->forgetChannels();
        config()->set('logging.channels.observability_stderr.handler_with.stream', $this->previousStream);
        unlink($this->path);
    }

    private function forgetChannels(): void
    {
        Log::forgetChannel('observability');
        Log::forgetChannel('observability_stderr');
    }
}
