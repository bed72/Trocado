<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Date;

it('shares sixty requests across contexts, tokens and IPs but isolates users', function (): void {
    $userId = signUpIdentityByApi($this);
    $firstToken = signInIdentityByApi($this);
    $secondToken = signInIdentityByApi($this);
    $otherUserId = signUpIdentityByApi($this, name: 'Joana', email: 'joana@example.com');
    $otherToken = signInIdentityByApi($this, email: 'joana@example.com');

    foreach (range(1, 60) as $attempt) {
        $this->withServerVariables(['REMOTE_ADDR' => $attempt % 2 ? '192.0.2.1' : '192.0.2.2'])
            ->withToken($attempt % 2 ? $firstToken : $secondToken);

        if ($attempt % 2) {
            $this->getJson(route('users.get', ['user' => $userId]))->assertOk();
        } else {
            $this->getJson(route('expenses.index'))->assertOk();
        }
    }

    $response = $this->withToken($secondToken)->postJson(route('expenses.create'), []);
    $response->assertStatus(429)->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'title' => 'Muitas solicitações',
            'detail' => 'O limite de solicitações foi excedido. Tente novamente mais tarde.',
            'status' => '429',
        ]]]);
    expect((int) $response->headers->get('Retry-After'))->toBeGreaterThan(0);
    $this->assertDatabaseCount('expenses', 0);

    app('auth')->forgetGuards();
    $this->withToken($otherToken)->getJson(route('users.get', ['user' => $otherUserId]))->assertOk();
    app('auth')->forgetGuards();
    $this->withToken($firstToken)->deleteJson(route('authentication.api.sign-out'))->assertNoContent();
    app('auth')->forgetGuards();
    $this->withToken($firstToken)->getJson(route('users.get', ['user' => $userId]))->assertUnauthorized();
});

it('authenticates before throttling and counts admitted errors but not public requests', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $this->withToken('invalid')->getJson(route('users.get', ['user' => $userId]))->assertUnauthorized();
    app('auth')->forgetGuards();
    $this->withToken('')->getJson(route('expenses.index'))->assertUnauthorized();
    app('auth')->forgetGuards();

    foreach (range(1, 60) as $attempt) {
        $this->withToken($token)->getJson(route('users.get', ['user' => $userId + 100]))->assertNotFound();
    }

    $this->withToken($token)->getJson(route('users.get', ['user' => $userId]))->assertStatus(429);
    app('auth')->forgetGuards();
    $this->withToken('invalid')->getJson(route('users.get', ['user' => $userId]))
        ->assertUnauthorized()->assertHeader('Content-Type', 'application/vnd.api+json');
    app('auth')->forgetGuards();
    $this->withToken('')->getJson(route('expenses.index'))->assertUnauthorized();
    $this->postJson(route('authentication.api.sign-in'), [])->assertUnprocessable();
    $this->postJson(route('authentication.api.sign-up'), [])->assertUnprocessable();
    app('auth')->forgetGuards();
    $this->withToken($token)->getJson(route('expenses.index'))->assertStatus(429);
});

it('admits the user again once the limiter window expires', function (): void {
    Date::setTestNow('2026-09-24 10:00:00');

    try {
        $userId = signUpIdentityByApi($this);
        $token = signInIdentityByApi($this);

        foreach (range(1, 60) as $attempt) {
            $this->withToken($token)->getJson(route('users.get', ['user' => $userId]))->assertOk();
        }

        $response = $this->withToken($token)->getJson(route('users.get', ['user' => $userId]));
        $response->assertStatus(429);
        Date::setTestNow(Date::now()->addSeconds((int) $response->headers->get('Retry-After') + 1));
        $this->withToken($token)->getJson(route('users.get', ['user' => $userId]))->assertOk();
    } finally {
        Date::setTestNow();
    }
});
