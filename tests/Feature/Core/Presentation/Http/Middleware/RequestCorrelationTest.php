<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;
use Tests\Support\Core\Fixtures\ObservabilityLogFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    $this->observabilityLog = new ObservabilityLogFixture;
});

afterEach(function (): void {
    $this->observabilityLog->close();
});

it('scopes correlation and principal to each request and leaves subsequent CLI events clean', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $user->forceFill(['id' => 1500])->save();
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    Route::get('/api/correlation-probe', function () {
        app(ObservabilityPort::class)->emit('probe.authenticated', ['expense_id' => 1500]);

        return response()->noContent();
    })->middleware(['auth:sanctum', 'request.authenticated']);
    Route::get('/api/public-correlation-probe', function () {
        app(ObservabilityPort::class)->emit('probe.public', []);

        return response()->noContent();
    });

    $first = $this->withToken($token)->getJson('/api/correlation-probe')->assertNoContent();
    Auth::forgetGuards();
    $second = $this->withToken($token)->getJson('/api/correlation-probe')->assertNoContent();
    Auth::forgetGuards();
    $public = $this->getJson('/api/public-correlation-probe')->assertNoContent();
    app(ObservabilityPort::class)->emit('outside.http', ['expense_id' => 1500]);

    $records = $this->observabilityLog->records();
    expect($records)->toHaveCount(4)
        ->and($first->headers->get('X-Request-Id'))->not->toBe($second->headers->get('X-Request-Id'));

    foreach ([$first, $second, $public] as $index => $response) {
        expect($records[$index]['request_id'])->toBe($response->headers->get('X-Request-Id'))
            ->and($records[$index]['level'])->toBe('INFO')
            ->and($records[$index]['timestamp'])->toBeString();
    }

    expect($records[0]['user_id'])->toBe(1500)
        ->and($records[1]['user_id'])->toBe(1500)
        ->and($records[2])->not->toHaveKey('user_id')
        ->and($records[3])->toMatchArray(['event' => 'outside.http', 'expense_id' => 1500])
        ->not->toHaveKeys(['request_id', 'user_id', 'trace_id', 'ip', 'route', 'path', 'http_method']);

    foreach ($records as $record) {
        expect($record)->not->toHaveKeys(['amount', 'description', 'password', 'token', 'payload'])
            ->and(array_values($record))->not->toContain($token);
    }
});
