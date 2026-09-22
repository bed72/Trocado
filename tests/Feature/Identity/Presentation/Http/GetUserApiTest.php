<?php

declare(strict_types=1);

beforeEach(function (): void {
    $this->userId = signUpIdentityByApi($this);
    $this->token = signInIdentityByApi($this);
});

it('returns the requested user as a complete JSON API resource', function (): void {
    $this->withToken($this->token)->getJson("/api/users/{$this->userId}")
        ->assertOk()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('data.id', (string) $this->userId)
        ->assertJsonPath('data.type', 'users')
        ->assertJsonPath('data.attributes.name', 'Maria')
        ->assertJsonPath('data.attributes.email', 'maria@example.com')
        ->assertJsonPath('data.links.self', route('users.get', ['user' => $this->userId]));
});

it('returns a complete JSON API error when the user does not exist', function (): void {
    $this->withToken($this->token)->getJson('/api/users/99999')
        ->assertNotFound()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '404',
            'title' => 'User não encontrado',
            'detail' => 'User não encontrado.',
        ]]]);
});

it('returns a route level JSON API error for a non numeric ID', function (): void {
    $this->withToken($this->token)->getJson('/api/users/not-a-number')
        ->assertNotFound()
        ->assertExactJson(['errors' => [[
            'status' => '404',
            'title' => 'Recurso não encontrado',
            'detail' => 'O recurso solicitado não foi encontrado.',
        ]]]);
});
