<?php

declare(strict_types=1);

namespace Tests\Support\Core\Load;

use InvalidArgumentException;
use JsonException;
use RuntimeException;
use SensitiveParameter;

use function in_array;
use function is_array;
use function is_int;
use function is_string;

final readonly class LoadConfiguration
{
    public function __construct(
        public string $targetUrl,
        public int $concurrency,
        public int $durationSeconds,
        public ?float $p95ThresholdMs,
        #[SensitiveParameter] private string $token,
    ) {
        $url = parse_url($targetUrl);
        if (! is_array($url) || filter_var($targetUrl, FILTER_VALIDATE_URL) === false
            || ! in_array($url['scheme'] ?? null, ['http', 'https'], true)
            || array_intersect(['user', 'pass', 'query', 'fragment'], array_keys($url)) !== []
            || ! in_array($url['path'] ?? '', ['', '/'], true)
            || ! (($url['host'] ?? '') === 'localhost' || ($url['host'] ?? '') === '127.0.0.1' || str_ends_with($url['host'] ?? '', '.test'))
            || preg_match('/\A[A-Za-z0-9|_.-]{1,4096}\z/', $token) !== 1) {
            throw new InvalidArgumentException('Load requires a local base URL without credentials and a Bearer token in private configuration.');
        }
        if ($concurrency < 1 || $concurrency > 100 || $durationSeconds < 1 || $durationSeconds > 30
            || ($p95ThresholdMs !== null && (! is_finite($p95ThresholdMs) || $p95ThresholdMs <= 0))) {
            throw new InvalidArgumentException('Load requires concurrency 1-100, duration 1-30 seconds and an optional positive p95 threshold.');
        }
    }

    /** @return array{Authorization: string, Accept: string} */
    public function headers(): array
    {
        return ['Authorization' => "Bearer {$this->token}", 'Accept' => 'application/vnd.api+json'];
    }

    public function redact(string $output): string
    {
        return str_replace([$this->token, rawurlencode($this->token)], '[redacted]', $output);
    }

    public static function fromEnvironment(): self
    {
        if (getenv('TROCADO_LOAD_RUN') !== '1' || ! is_string($path = getenv('TROCADO_LOAD_CONFIG')) || $path === '') {
            throw new RuntimeException('Run composer test:load with TROCADO_LOAD_CONFIG pointing to a private JSON configuration.');
        }

        return self::fromFile($path, dirname(__DIR__, 4));
    }

    public static function fromFile(string $path, string $root): self
    {
        $realPath = realpath($path);
        $realRoot = realpath($root);
        if ($realPath === false || $realRoot === false || $realPath !== $path
            || $realPath === $realRoot || str_starts_with($realPath, $realRoot.DIRECTORY_SEPARATOR)) {
            throw new RuntimeException('Load configuration must be a canonical private file outside the repository.');
        }

        $handle = @fopen($realPath, 'rb');
        if ($handle === false) {
            throw new RuntimeException('Cannot open private Load configuration.');
        }
        try {
            $stat = fstat($handle);
            if ($stat === false || ($stat['mode'] & 0170000) !== 0100000 || ($stat['mode'] & 0077) !== 0 || $stat['size'] > 65536) {
                throw new RuntimeException('Load configuration must be a private regular file of at most 64 KiB.');
            }
            $contents = stream_get_contents($handle, 65537);
            if ($contents === false || strlen($contents) > 65536) {
                throw new RuntimeException('Cannot read private Load configuration.');
            }
            try {
                $data = json_decode($contents, true, flags: JSON_THROW_ON_ERROR);
            } catch (JsonException) {
                throw new RuntimeException('Invalid Load configuration JSON.');
            }
        } finally {
            fclose($handle);
        }

        if (! is_array($data) || ($data['version'] ?? null) !== 1 || ($data['dedicatedTarget'] ?? null) !== true
            || array_diff(array_keys($data), ['version', 'targetUrl', 'token', 'dedicatedTarget', 'concurrency', 'durationSeconds', 'p95ThresholdMs']) !== []
            || ! is_string($data['targetUrl'] ?? null) || ! is_string($data['token'] ?? null)
            || ! is_int($data['concurrency'] ?? 1) || ! is_int($data['durationSeconds'] ?? 5)
            || (isset($data['p95ThresholdMs']) && ! is_int($data['p95ThresholdMs']) && ! is_float($data['p95ThresholdMs']))) {
            throw new RuntimeException('Invalid Load configuration or missing explicit dedicatedTarget confirmation.');
        }

        return new self(
            targetUrl: $data['targetUrl'],
            concurrency: $data['concurrency'] ?? 1,
            durationSeconds: $data['durationSeconds'] ?? 5,
            p95ThresholdMs: $data['p95ThresholdMs'] ?? null,
            token: $data['token'],
        );
    }
}
