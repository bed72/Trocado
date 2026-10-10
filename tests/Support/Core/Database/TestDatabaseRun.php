<?php

declare(strict_types=1);

namespace Tests\Support\Core\Database;

use RuntimeException;

final readonly class TestDatabaseRun
{
    public const BASE = 'trocado_testing';

    public string $database;

    /** @param list<string> $tokens */
    public function __construct(public string $id, public string $owner, public array $tokens = [], public ?string $token = null)
    {
        if (preg_match('/\A[a-f0-9]{24}\z/', $id) !== 1 || preg_match('/\A[a-f0-9]{64}\z/', $owner) !== 1) {
            throw new RuntimeException('Invalid test execution identity. Use composer test -- <path>.');
        }

        foreach ($tokens as $registered) {
            if (preg_match('/\A[1-9][0-9]{0,2}\z/', $registered) !== 1) {
                throw new RuntimeException('Invalid parallel process token.');
            }
        }

        if ($token !== null && ! in_array($token, $tokens, true)) {
            throw new RuntimeException('Unregistered parallel process token.');
        }

        $this->database = self::BASE.'_'.$id.($token === null ? '' : '_test_'.$token);
    }

    public static function create(int $processes = 0): self
    {
        return new self(bin2hex(random_bytes(12)), bin2hex(random_bytes(32)), $processes === 0 ? [] : array_map(strval(...), range(1, $processes)));
    }

    public static function fromEnvironment(bool $process = true): self
    {
        $path = getenv('TROCADO_TEST_MANIFEST');

        if (! is_string($path) || ! is_file($path)) {
            throw new RuntimeException('Missing test preflight. Run composer test -- <path> (Lerd: lerd composer test -- <path>).');
        }

        $manifest = json_decode(file_get_contents($path), true, flags: JSON_THROW_ON_ERROR);

        if (! is_array($manifest) || ! is_string($manifest['id'] ?? null) || ! is_string($manifest['owner'] ?? null)) {
            throw new RuntimeException('Invalid test ownership manifest.');
        }

        $token = $process ? getenv('TEST_TOKEN') : false;

        return new self($manifest['id'], $manifest['owner'], $manifest['tokens'] ?? [], $token === false || $token === '' ? null : $token);
    }

    public function writeManifest(): string
    {
        $path = tempnam(sys_get_temp_dir(), 'trocado-test-');

        if ($path === false || ! chmod($path, 0600)
            || file_put_contents($path, json_encode(['id' => $this->id, 'owner' => $this->owner, 'tokens' => $this->tokens], JSON_THROW_ON_ERROR)) === false) {
            throw new RuntimeException('Cannot register ownership of this test execution.');
        }

        return $path;
    }

    public function marker(): string
    {
        return 'trocado-test:'.$this->id.':'.$this->owner;
    }

    public function forToken(string $token): self
    {
        return new self($this->id, $this->owner, $this->tokens, $token);
    }
}
