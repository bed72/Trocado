<?php

declare(strict_types=1);

namespace Tests\Support\Core\Load;

use InvalidArgumentException;
use RuntimeException;
use Throwable;

use function in_array;

final readonly class LoadManifest
{
    private function __construct(
        public string $runId,
        private string $owner,
        public string $objective,
        public LoadScenarioEnum $scenario,
        public LoadConfiguration $configuration,
    ) {}

    public static function plan(LoadScenarioEnum $scenario, string $objective, LoadConfiguration $configuration): self
    {
        if (! in_array($objective, ['capacity', 'regression'], true)) {
            throw new InvalidArgumentException('Invalid Load objective.');
        }

        return new self(bin2hex(random_bytes(12)), bin2hex(random_bytes(32)), $objective, $scenario, $configuration);
    }

    /** @return array<string, mixed> */
    public function toArray(): array
    {
        return [
            'version' => 1,
            'lease' => null,
            'resources' => [],
            'runId' => $this->runId,
            'owner' => $this->owner,
            'targetVerification' => null,
            'objective' => $this->objective,
            'scenario' => $this->scenario->value,
            'limits' => $this->configuration->limits,
            'state' => LoadStateEnum::Pending->value,
            'phase' => LoadPhaseEnum::Preflight->value,
            'profile' => $this->configuration->profile,
            'targetUrl' => $this->configuration->targetUrl,
            'datasetId' => $this->configuration->datasetId,
        ];
    }

    public function write(string $root): string
    {
        $parent = realpath(sys_get_temp_dir());
        $realRoot = realpath($root);
        if ($parent === false || $realRoot === false || $parent === $realRoot || str_starts_with($parent, $realRoot.DIRECTORY_SEPARATOR)) {
            throw new RuntimeException('Load manifests require a temporary directory outside the repository.');
        }
        $directory = "{$parent}/trocado-load-{$this->runId}";
        if (! @mkdir($directory, 0700)) {
            throw new RuntimeException('Cannot allocate private Load manifest directory.');
        }

        $path = "{$directory}/manifest.json";
        try {
            $handle = @fopen($path, 'x');
            if ($handle === false) {
                throw new RuntimeException('Cannot create private Load manifest.');
            }
            try {
                if (! chmod($path, 0600)) {
                    throw new RuntimeException('Cannot protect private Load manifest.');
                }
                $json = json_encode($this->toArray(), JSON_THROW_ON_ERROR | JSON_PRETTY_PRINT);
                if (fwrite($handle, $json) !== strlen($json)) {
                    throw new RuntimeException('Cannot persist private Load manifest.');
                }
            } finally {
                fclose($handle);
            }
        } catch (Throwable) {
            if (is_file($path)) {
                unlink($path);
            }
            rmdir($directory);

            throw new RuntimeException('Cannot persist private Load manifest.');
        }

        return $path;
    }
}
