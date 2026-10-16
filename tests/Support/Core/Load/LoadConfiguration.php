<?php

declare(strict_types=1);

namespace Tests\Support\Core\Load;

use InvalidArgumentException;
use JsonException;
use RuntimeException;

use function count;
use function in_array;
use function is_array;
use function is_int;
use function is_string;

final readonly class LoadConfiguration
{
    /** @param array{concurrency: list<int>, durationSeconds: int, warmupSeconds: int, requestTimeoutSeconds: int, processTimeoutSeconds: int, recoveryTimeoutSeconds: int, campaignTimeoutSeconds: int, maxRequests: int} $limits */
    public function __construct(public string $targetUrl, public string $datasetId, public string $profile, public array $limits)
    {
        $url = parse_url($targetUrl);
        if (! is_array($url) || filter_var($targetUrl, FILTER_VALIDATE_URL) === false
            || ! in_array($url['scheme'] ?? null, ['http', 'https'], true)
            || array_intersect(['user', 'pass', 'query', 'fragment'], array_keys($url)) !== []
            || ! in_array($url['path'] ?? '', ['', '/'], true)
            || preg_match('/\A[a-z0-9][a-z0-9-]{0,63}\z/', $datasetId) !== 1
            || ! in_array($profile, ['capacity', 'protection'], true)) {
            throw new InvalidArgumentException('Invalid Load URL, dataset or profile; values are not echoed.');
        }

        $integerKeys = ['durationSeconds', 'warmupSeconds', 'requestTimeoutSeconds', 'processTimeoutSeconds', 'recoveryTimeoutSeconds', 'campaignTimeoutSeconds', 'maxRequests'];
        if (count($limits) !== 8 || array_diff(array_keys($limits), ['concurrency', ...$integerKeys]) !== []) {
            throw new InvalidArgumentException('Load limits require exactly the documented fields.');
        }
        foreach ($integerKeys as $key) {
            if (! is_int($limits[$key] ?? null) || $limits[$key] < 1) {
                throw new InvalidArgumentException('Load limits must be explicit positive integers.');
            }
        }

        $concurrency = $limits['concurrency'] ?? null;
        if (! is_array($concurrency) || ! array_is_list($concurrency) || $concurrency === []
            || ! array_all($concurrency, static fn (mixed $value): bool => is_int($value) && in_array($value, [1, 5, 10, 20], true))
            || count(array_unique($concurrency)) !== count($concurrency)
            || $limits['durationSeconds'] !== 30
            || $limits['requestTimeoutSeconds'] >= $limits['processTimeoutSeconds']
            || $limits['processTimeoutSeconds'] <= $limits['durationSeconds']
            || $limits['campaignTimeoutSeconds'] <= $limits['processTimeoutSeconds']) {
            throw new InvalidArgumentException('Invalid initial Load concurrency, duration or timeout bounds.');
        }
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

        if (! is_array($data) || count($data) !== 5 || ($data['version'] ?? null) !== 1
            || array_diff(array_keys($data), ['version', 'targetUrl', 'datasetId', 'profile', 'limits']) !== []
            || ! is_string($data['targetUrl'] ?? null) || ! is_string($data['datasetId'] ?? null)
            || ! is_string($data['profile'] ?? null) || ! is_array($data['limits'] ?? null)) {
            throw new RuntimeException('Invalid Load configuration fields; credentials are not accepted here.');
        }

        return new self($data['targetUrl'], $data['datasetId'], $data['profile'], $data['limits']);
    }
}
