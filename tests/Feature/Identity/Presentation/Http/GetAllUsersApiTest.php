<?php

declare(strict_types=1);

it('returns the authenticated identity in the JSON API user collection', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $this->withToken($token)->getJson(route('users.get-all'))
        ->assertOk()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.id', (string) $userId);
});

it('lists users in identifier order', function (): void {
    $firstId = signUpIdentityByApi($this);
    $secondId = signUpIdentityByApi($this, name: 'João', email: 'joao@example.com');
    $token = signInIdentityByApi($this);

    $this->withToken($token)->getJson(route('users.get-all'))
        ->assertOk()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonCount(2, 'data')
        ->assertJsonPath('data.0.id', (string) $firstId)
        ->assertJsonPath('data.0.attributes.email', 'maria@example.com')
        ->assertJsonPath('data.1.id', (string) $secondId)
        ->assertJsonPath('data.1.attributes.email', 'joao@example.com');
});
