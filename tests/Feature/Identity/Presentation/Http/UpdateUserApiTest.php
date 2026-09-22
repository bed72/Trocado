<?php

declare(strict_types=1);

beforeEach(function (): void {
    $this->userId = signUpIdentityByApi($this);
    $this->token = signInIdentityByApi($this);
});

it('updates the name while preserving the email', function (): void {
    $this->withToken($this->token)->patchJson("/api/users/{$this->userId}", updateUserApiPayload(
        id: $this->userId,
        attributes: ['name' => '  Maria Souza  '],
    ))->assertOk()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('data.attributes.name', 'Maria Souza')
        ->assertJsonPath('data.attributes.email', 'maria@example.com');

    $this->assertDatabaseHas('users', [
        'id' => $this->userId,
        'name' => 'Maria Souza',
        'email' => 'maria@example.com',
    ]);
});

it('updates and normalizes email while preserving the name', function (): void {
    $this->withToken($this->token)->patchJson("/api/users/{$this->userId}", updateUserApiPayload(
        id: $this->userId,
        attributes: ['email' => ' MARIA.SOUZA@EXAMPLE.COM '],
    ))->assertOk()
        ->assertJsonPath('data.attributes.name', 'Maria')
        ->assertJsonPath('data.attributes.email', 'maria.souza@example.com');
});

it('allows the current canonical email', function (): void {
    $this->withToken($this->token)->patchJson("/api/users/{$this->userId}", updateUserApiPayload(
        id: $this->userId,
        attributes: ['email' => ' MARIA@EXAMPLE.COM '],
    ))->assertOk()
        ->assertJsonPath('data.attributes.email', 'maria@example.com');
});

it('returns a conflict when updating to another user email', function (): void {
    signUpIdentityByApi($this, name: 'João', email: 'joao@example.com');

    $this->withToken($this->token)->patchJson("/api/users/{$this->userId}", updateUserApiPayload(
        id: $this->userId,
        attributes: ['email' => ' JOAO@EXAMPLE.COM '],
    ))->assertConflict()
        ->assertExactJson(['errors' => [[
            'status' => '409',
            'title' => 'E-mail já utilizado',
            'detail' => 'Não foi possível utilizar o e-mail informado.',
            'source' => ['pointer' => '/data/attributes/email'],
        ]]]);

    $this->assertDatabaseHas('users', ['id' => $this->userId, 'email' => 'maria@example.com']);
});

it('rejects invalid update documents without changing the user', function (array $attributes, string $pointer): void {
    $this->withToken($this->token)->patchJson("/api/users/{$this->userId}", updateUserApiPayload(
        id: $this->userId,
        attributes: $attributes,
    ))->assertUnprocessable()
        ->assertJsonFragment(['source' => ['pointer' => $pointer]]);

    $this->assertDatabaseHas('users', ['id' => $this->userId, 'name' => 'Maria', 'email' => 'maria@example.com']);
})->with([
    'empty attributes' => [[], '/data/attributes'],
    'unexpected attribute' => [['password' => 'secret'], '/data/attributes'],
    'null name' => [['name' => null], '/data/attributes/name'],
    'name below letter minimum' => [['name' => 'A'], '/data/attributes/name'],
    'name above letter maximum' => [['name' => str_repeat('a', 13)], '/data/attributes/name'],
    'name with invalid characters' => [['name' => 'Maria2'], '/data/attributes/name'],
    'invalid email' => [['email' => 'invalid'], '/data/attributes/email'],
]);

it('rejects a mismatched resource ID', function (): void {
    $this->withToken($this->token)->patchJson("/api/users/{$this->userId}", updateUserApiPayload(
        id: 99999,
        attributes: ['name' => 'Maria Souza'],
    ))->assertUnprocessable()
        ->assertJsonFragment(['source' => ['pointer' => '/data/id']]);
});

it('returns a JSON API error when updating an absent user', function (): void {
    $this->withToken($this->token)->patchJson('/api/users/99999', updateUserApiPayload(
        id: 99999,
        attributes: ['name' => 'Maria'],
    ))->assertNotFound()
        ->assertJsonPath('errors.0.status', '404')
        ->assertJsonPath('errors.0.title', 'User não encontrado');
});

function updateUserApiPayload(int $id, array $attributes): array
{
    return [
        'data' => [
            'type' => 'users',
            'id' => (string) $id,
            'attributes' => $attributes,
        ],
    ];
}
