<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Date;

beforeEach(function (): void {
    config()->set('cache.default', 'array');
});

it('limits canonical sign in identifiers and admits requests after the wait', function (): void {
    Date::setTestNow('2026-09-24 10:00:00');

    try {
        foreach (range(1, 5) as $attempt) {
            $this->postJson(route('authentication.api.sign-in'), throttleSignInPayload(
                $attempt % 2 === 0 ? '  MARIA@EXAMPLE.COM  ' : 'maria@example.com',
            ))->assertUnauthorized();
        }

        $response = $this->postJson(route('authentication.api.sign-in'), throttleSignInPayload(' Maria@Example.com '));
        $response->assertStatus(429)
            ->assertHeader('Content-Type', 'application/vnd.api+json')
            ->assertExactJson(['errors' => [[
                'title' => 'Muitas solicitações',
                'detail' => 'O limite de solicitações foi excedido. Tente novamente mais tarde.',
                'status' => '429',
            ]]]);
        expect((int) $response->headers->get('Retry-After'))->toBeGreaterThan(0);
        $this->assertDatabaseCount('personal_access_tokens', 0);

        Date::setTestNow(Date::now()->addSeconds((int) $response->headers->get('Retry-After') + 1));
        $this->postJson(route('authentication.api.sign-in'), throttleSignInPayload('maria@example.com'))
            ->assertUnauthorized();
    } finally {
        Date::setTestNow();
    }
});

it('limits sign in by IP even when emails vary and does not block another IP', function (): void {
    foreach (range(1, 30) as $attempt) {
        $this->postJson(route('authentication.api.sign-in'), throttleSignInPayload("missing{$attempt}@example.com"))
            ->assertUnauthorized();
    }

    $this->postJson(route('authentication.api.sign-in'), throttleSignInPayload('new@example.com'))
        ->assertStatus(429);
    $this->withServerVariables(['REMOTE_ADDR' => '192.0.2.12'])
        ->postJson(route('authentication.api.sign-in'), throttleSignInPayload('new@example.com'))
        ->assertUnauthorized();
});

it('limits sign up independently by IP before validation or user creation', function (): void {
    foreach (range(1, 3) as $attempt) {
        $this->postJson(route('authentication.api.sign-up'), [])->assertUnprocessable();
    }

    $response = $this->postJson(route('authentication.api.sign-up'), throttleSignUpPayload());
    $response->assertStatus(429)
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('errors.0.status', '429');
    expect((int) $response->headers->get('Retry-After'))->toBeGreaterThan(0);
    $this->assertDatabaseCount('users', 0);
    $this->assertDatabaseCount('personal_access_tokens', 0);

    $this->postJson(route('authentication.api.sign-in'), throttleSignInPayload())->assertUnauthorized();
    $this->withServerVariables(['REMOTE_ADDR' => '192.0.2.13'])
        ->postJson(route('authentication.api.sign-up'), throttleSignUpPayload())->assertCreated();
    $this->assertDatabaseCount('users', 1);
});

function throttleSignInPayload(string $email = 'maria@example.com'): array
{
    return ['data' => ['type' => 'access-tokens', 'attributes' => [
        'email' => $email,
        'password' => 'Incorrect1',
    ]]];
}

function throttleSignUpPayload(): array
{
    return ['data' => ['type' => 'sign-ups', 'attributes' => [
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Correct1',
        'password_confirmation' => 'Correct1',
    ]]];
}
