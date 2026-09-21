<?php

declare(strict_types=1);

use App\User\Infrastructure\Persistence\Models\UserModel;

beforeEach(function (): void {
    $this->user = UserModel::query()->create(['name' => 'Maria', 'email' => 'maria@example.com']);
});

it('updates the name while preserving the email', function (): void {
    $this->patchJson("/api/users/{$this->user->getKey()}", updateUserApiPayload(
        id: (int) $this->user->getKey(),
        attributes: ['name' => '  Maria Souza  '],
    ))->assertOk()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('data.attributes.name', 'Maria Souza')
        ->assertJsonPath('data.attributes.email', 'maria@example.com');

    $this->assertDatabaseHas('users', [
        'id' => $this->user->getKey(),
        'name' => 'Maria Souza',
        'email' => 'maria@example.com',
    ]);
});

it('updates and normalizes email while preserving the name', function (): void {
    $this->patchJson("/api/users/{$this->user->getKey()}", updateUserApiPayload(
        id: (int) $this->user->getKey(),
        attributes: ['email' => ' MARIA.SOUZA@EXAMPLE.COM '],
    ))->assertOk()
        ->assertJsonPath('data.attributes.name', 'Maria')
        ->assertJsonPath('data.attributes.email', 'maria.souza@example.com');
});

it('allows the current canonical email', function (): void {
    $this->patchJson("/api/users/{$this->user->getKey()}", updateUserApiPayload(
        id: (int) $this->user->getKey(),
        attributes: ['email' => ' MARIA@EXAMPLE.COM '],
    ))->assertOk()
        ->assertJsonPath('data.attributes.email', 'maria@example.com');
});

it('returns a conflict when updating to another user email', function (): void {
    UserModel::query()->create(['name' => 'João', 'email' => 'joao@example.com']);

    $this->patchJson("/api/users/{$this->user->getKey()}", updateUserApiPayload(
        id: (int) $this->user->getKey(),
        attributes: ['email' => ' JOAO@EXAMPLE.COM '],
    ))->assertConflict()
        ->assertExactJson(['errors' => [[
            'status' => '409',
            'title' => 'E-mail já utilizado',
            'detail' => 'Não foi possível utilizar o e-mail informado.',
        ]]]);

    $this->assertDatabaseHas('users', ['id' => $this->user->getKey(), 'email' => 'maria@example.com']);
});

it('rejects invalid update documents without changing the user', function (array $attributes, string $pointer): void {
    $this->patchJson("/api/users/{$this->user->getKey()}", updateUserApiPayload(
        id: (int) $this->user->getKey(),
        attributes: $attributes,
    ))->assertUnprocessable()
        ->assertJsonFragment(['source' => ['pointer' => $pointer]]);

    $this->assertDatabaseHas('users', ['id' => $this->user->getKey(), 'name' => 'Maria', 'email' => 'maria@example.com']);
})->with([
    'empty attributes' => [[], '/data/attributes'],
    'unexpected attribute' => [['password' => 'secret'], '/data/attributes'],
    'null name' => [['name' => null], '/data/attributes/name'],
    'invalid email' => [['email' => 'invalid'], '/data/attributes/email'],
]);

it('rejects a mismatched resource ID', function (): void {
    $this->patchJson("/api/users/{$this->user->getKey()}", updateUserApiPayload(
        id: 99999,
        attributes: ['name' => 'Maria Souza'],
    ))->assertUnprocessable()
        ->assertJsonFragment(['source' => ['pointer' => '/data/id']]);
});

it('returns a JSON API error when updating an absent user', function (): void {
    $this->patchJson('/api/users/99999', updateUserApiPayload(
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
