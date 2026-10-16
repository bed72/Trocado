<?php

declare(strict_types=1);

namespace Tests\Support\Core\Load;

use JsonException;
use RuntimeException;

use function Pest\Stressless\stress;

final readonly class LoadHttpScenario
{
    public function __construct(private LoadConfiguration $configuration) {}

    /** @return array{scenario: string, concurrency: int, durationSeconds: int, requests: int, requestsPerSecond: float, failureFraction: float, p50Ms: float, p95Ms: float} */
    public function run(LoadScenarioEnum $scenario): array
    {
        $path = $scenario->endpoint().($scenario === LoadScenarioEnum::ExpenseSuggestions ? '?query=teste' : '');
        $url = rtrim($this->configuration->targetUrl, '/').$path;
        $curl = curl_init($url);
        if ($curl === false) {
            throw new RuntimeException('Load preflight could not initialize HTTP.');
        }
        try {
            curl_setopt_array($curl, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_FOLLOWLOCATION => false,
                CURLOPT_CONNECTTIMEOUT => 3,
                CURLOPT_TIMEOUT => 5,
                CURLOPT_HTTPHEADER => array_map(static fn (string $name, string $value): string => "{$name}: {$value}", array_keys($this->configuration->headers()), array_values($this->configuration->headers())),
            ]);
            $body = curl_exec($curl);
            if ($body === false || curl_getinfo($curl, CURLINFO_RESPONSE_CODE) !== 200) {
                throw new RuntimeException('Load preflight requires HTTP 200; verify credentials, account status, limiter and target.');
            }
            try {
                $document = json_decode($body, true, flags: JSON_THROW_ON_ERROR);
            } catch (JsonException) {
                throw new RuntimeException('Load preflight requires valid JSON:API.');
            }
            if (! is_array($document) || ! is_array($document['data'] ?? null) || isset($document['errors'])) {
                throw new RuntimeException('Load preflight requires a JSON:API data document.');
            }
        } finally {
            unset($curl);
        }

        $result = stress($url)
            ->headers($this->configuration->headers())
            ->concurrently($this->configuration->concurrency)
            ->for($this->configuration->durationSeconds)->seconds()
            ->run();
        $requests = $result->requests();

        return [
            'scenario' => $scenario->value,
            'concurrency' => $this->configuration->concurrency,
            'durationSeconds' => $this->configuration->durationSeconds,
            'requests' => $requests->count(),
            'requestsPerSecond' => $requests->rate(),
            'failureFraction' => $requests->failed()->rate(),
            'p50Ms' => $requests->duration()->med(),
            'p95Ms' => $requests->duration()->p95(),
        ];
    }
}
