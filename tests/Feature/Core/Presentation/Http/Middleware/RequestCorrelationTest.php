<?php

declare(strict_types=1);

use App\Core\Application\Ports\ContextPort;
use App\Core\Application\Ports\ObservabilityPort;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Context;
use Illuminate\Support\Facades\Route;
use Tests\Support\Core\Fixtures\ObservabilityLogFixture;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    $this->observabilityLog = new ObservabilityLogFixture;
});

afterEach(function (): void {
    $this->observabilityLog->close();
});

it('scopes correlation and principal to each request and leaves subsequent CLI events clean', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $userId = $user->getKey();
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    Route::get('/api/correlation-probe', function (Request $request, ContextPort $port) {
        expect($request->attributes->get('trace_id'))->toBe($port->traceId())
            ->and($request->attributes->has('request_id'))->toBeFalse()
            ->and(Context::has('request_id'))->toBeFalse()
            ->and(Context::get('trace_id'))->toBe($port->traceId());
        app(ObservabilityPort::class)->emit('probe.authenticated', ['expense_id' => UuidFixture::at(1500)]);

        return response()->noContent();
    })->middleware(['auth:sanctum', 'request.authenticated']);
    Route::get('/api/public-correlation-probe', function () {
        app(ObservabilityPort::class)->emit('probe.public', []);

        return response()->noContent();
    });

    $clientId = UuidFixture::at(42);
    $first = $this->withHeader('X-Request-Id', $clientId)->withToken($token)->getJson('/api/correlation-probe')->assertNoContent();
    Auth::forgetGuards();
    $second = $this->withToken($token)->getJson('/api/correlation-probe')->assertNoContent();
    Auth::forgetGuards();
    $public = $this->getJson('/api/public-correlation-probe')->assertNoContent();
    app(ObservabilityPort::class)->emit('outside.http', ['expense_id' => UuidFixture::at(1500)]);

    $records = $this->observabilityLog->records();
    expect($records)->toHaveCount(4)
        ->and(array_unique([$first->headers->get('X-Request-Id'), $second->headers->get('X-Request-Id'), $public->headers->get('X-Request-Id')]))->toHaveCount(3);

    foreach ([$first, $second, $public] as $index => $response) {
        expect($records[$index]['trace_id'])->toBe($response->headers->get('X-Request-Id'))
            ->toMatch('/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/D')
            ->not->toBe($clientId)
            ->and($records[$index])->not->toHaveKeys(['request_id', 'route'])
            ->and($records[$index]['path'])->toBe($index === 2 ? '/api/public-correlation-probe' : '/api/correlation-probe')
            ->and($records[$index]['level'])->toBe('INFO')
            ->and($records[$index]['timestamp'])->toBeString();
    }

    expect($records[0]['user_id'])->toBe($userId)
        ->and($records[1]['user_id'])->toBe($userId)
        ->and($records[2])->not->toHaveKey('user_id')
        ->and($records[3])->toMatchArray(['event' => 'outside.http', 'expense_id' => UuidFixture::at(1500)])
        ->not->toHaveKeys(['request_id', 'user_id', 'trace_id', 'ip', 'route', 'path', 'http_method']);

    foreach ($records as $record) {
        expect($record)->not->toHaveKeys(['amount', 'description', 'password', 'token', 'payload', 'components', 'logical_key', 'logical_fingerprint', 'identifier_fingerprint'])
            ->and(array_values($record))->not->toContain($token);
    }
});
