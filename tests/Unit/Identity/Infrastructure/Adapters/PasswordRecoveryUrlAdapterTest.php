<?php

declare(strict_types=1);

use App\Identity\Infrastructure\Adapters\PasswordRecoveryUrlAdapter;
use Illuminate\Config\Repository;

it('returns only the configured absolute destination preserving its non reserved query', function (string $url, string $environment): void {
    $adapter = new PasswordRecoveryUrlAdapter(new Repository([
        'app' => ['env' => $environment],
        'identity' => ['password_recovery' => ['url' => $url]],
    ]));

    expect($adapter->baseUrl())->toBe($url);
})->with([
    'production https' => ['https://app.example.com/reset-password', 'production'],
    'existing query' => ['https://app.example.com/reset-password?locale=pt-BR&source=email', 'production'],
    'encoded non reserved query' => ['https://app.example.com/reset?return=%2Fwelcome%3Ftoken%3Dother', 'production'],
    'local http' => ['http://app.test:8080/reset-password', 'local'],
]);

it('rejects unavailable unsafe or reserved destinations without exposing their value or using a fallback', function (mixed $url, string $environment): void {
    $adapter = new PasswordRecoveryUrlAdapter(new Repository([
        'app' => ['env' => $environment, 'url' => 'https://api.example.com'],
        'identity' => ['password_recovery' => ['url' => $url]],
    ]));

    try {
        $adapter->baseUrl();
        $this->fail('An invalid recovery destination must be rejected.');
    } catch (RuntimeException $exception) {
        expect($exception->getMessage())->toBe('O destino de recuperação de senha não está configurado corretamente.')
            ->and($exception->getPrevious())->toBeNull();
    }
})->with([
    'missing' => [null, 'production'],
    'empty' => ['', 'production'],
    'array' => [[], 'production'],
    'relative' => ['/reset-password', 'production'],
    'scheme relative' => ['//app.example.com/reset-password', 'production'],
    'malformed host' => ['https:///reset-password', 'production'],
    'http in production' => ['http://app.example.com/reset-password', 'production'],
    'unsupported scheme' => ['ftp://app.example.com/reset-password', 'local'],
    'fragment' => ['https://app.example.com/reset-password#secret', 'production'],
    'empty fragment' => ['https://app.example.com/reset-password#', 'production'],
    'userinfo' => ['https://user:private@app.example.com/reset-password', 'production'],
    'user only' => ['https://user@app.example.com/reset-password', 'production'],
    'token' => ['https://app.example.com/reset-password?token=private', 'production'],
    'email' => ['https://app.example.com/reset-password?email=private', 'production'],
    'encoded reserved key' => ['https://app.example.com/reset-password?%74oken=private', 'production'],
    'reserved key without value' => ['https://app.example.com/reset-password?locale=pt&email', 'production'],
    'array reserved key' => ['https://app.example.com/reset-password?token%5B%5D=private', 'production'],
    'case variant' => ['https://app.example.com/reset-password?TOKEN=private', 'production'],
    'semicolon separator' => ['https://app.example.com/reset-password?locale=pt;email=private', 'production'],
    'invalid port' => ['https://app.example.com:99999/reset-password', 'production'],
]);
