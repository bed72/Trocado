<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Adapters;

use Illuminate\Contracts\Config\Repository;
use RuntimeException;
use SensitiveParameter;

use function in_array;
use function is_string;

final readonly class PasswordRecoveryUrlAdapter
{
    public function __construct(private Repository $repository) {}

    public function baseUrl(): string
    {
        $url = $this->repository->get('identity.password_recovery.url');

        if (! is_string($url) || filter_var($url, FILTER_VALIDATE_URL) === false) {
            throw new RuntimeException('O destino de recuperação de senha não está configurado corretamente.');
        }

        $parts = parse_url($url);

        if ($parts === false
            || ! in_array($parts['scheme'] ?? '', ['https', 'http'], true)
            || ($this->repository->get('app.env') === 'production' && $parts['scheme'] !== 'https')
            || isset($parts['user']) || isset($parts['pass']) || isset($parts['fragment'])
            || $this->hasReservedQuery($parts['query'] ?? '')) {
            throw new RuntimeException('O destino de recuperação de senha não está configurado corretamente.');
        }

        return $url;
    }

    private function hasReservedQuery(string $query): bool
    {
        foreach (preg_split('/[&;]/', $query) as $parameter) {
            $name = urldecode(explode('=', $parameter, 2)[0]);

            if (preg_match('/\A(?:token|email)(?:\[|\z)/i', $name) === 1) {
                return true;
            }
        }

        return false;
    }

    public function forToken(string $email, #[SensitiveParameter] string $token): string
    {
        $baseUrl = $this->baseUrl();
        $query = http_build_query(['token' => $token, 'email' => $email], arg_separator: '&', encoding_type: PHP_QUERY_RFC3986);
        $separator = str_contains($baseUrl, '?') ? '&' : '?';

        return "{$baseUrl}{$separator}{$query}";
    }
}
