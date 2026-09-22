<?php

declare(strict_types=1);

it('deletes a user with every token and rejects both bearer tokens afterwards', function (): void {
    $userId = signUpIdentityByApi($this);
    $firstToken = signInIdentityByApi($this);
    $secondToken = signInIdentityByApi($this);

    $this->withToken($firstToken)
        ->deleteJson("/api/users/{$userId}")
        ->assertNoContent();

    $this->assertDatabaseMissing('users', ['id' => $userId]);
    $this->assertDatabaseCount('personal_access_tokens', 0);

    app('auth')->forgetGuards();
    $this->withToken($firstToken)->getJson("/api/users/{$userId}")->assertUnauthorized();
    app('auth')->forgetGuards();
    $this->withToken($secondToken)->getJson("/api/users/{$userId}")->assertUnauthorized();
});

it('returns a complete JSON API error when the user does not exist', function (): void {
    signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $this->withToken($token)->deleteJson('/api/users/99999')
        ->assertNotFound()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '404',
            'title' => 'User não encontrado',
            'detail' => 'User não encontrado.',
        ]]]);
});

it('returns a route level JSON API error for a non numeric ID', function (): void {
    signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $this->withToken($token)->deleteJson('/api/users/not-a-number')
        ->assertNotFound()
        ->assertExactJson(['errors' => [[
            'status' => '404',
            'title' => 'Recurso não encontrado',
            'detail' => 'O recurso solicitado não foi encontrado.',
        ]]]);
});
