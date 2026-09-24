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

it('cannot delete another account or its tokens', function (): void {
    $ownerId = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $otherId = signUpIdentityByApi($this, name: 'João', email: 'joao@example.com');
    $otherToken = signInIdentityByApi($this, email: 'joao@example.com');
    app('auth')->forgetGuards();
    $expenseId = $this->withToken($otherToken)->postJson('/api/expenses', [
        'data' => ['type' => 'expenses', 'attributes' => ['amount' => 1250]],
    ])->assertCreated()->json('data.id');
    app('auth')->forgetGuards();
    $missing = $this->withToken($token)->deleteJson('/api/users/99999')->json();

    $this->withToken($token)->deleteJson("/api/users/{$otherId}")
        ->assertNotFound()->assertExactJson($missing);
    $this->assertDatabaseHas('users', ['id' => $otherId, 'email' => 'joao@example.com']);
    $this->assertDatabaseHas('expenses', ['id' => $expenseId, 'user_id' => $otherId, 'amount' => 1250]);
    $this->assertDatabaseCount('personal_access_tokens', 2);
    app('auth')->forgetGuards();
    $this->withToken($otherToken)->getJson("/api/users/{$otherId}")->assertOk();
});

it('requires authentication to delete a user', function (): void {
    $userId = signUpIdentityByApi($this);
    $this->withToken('invalid')->deleteJson("/api/users/{$userId}")
        ->assertUnauthorized()->assertHeader('Content-Type', 'application/vnd.api+json');
    $this->assertDatabaseHas('users', ['id' => $userId]);
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
