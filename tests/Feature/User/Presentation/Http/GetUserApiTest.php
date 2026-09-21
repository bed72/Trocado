<?php

declare(strict_types=1);

use App\User\Infrastructure\Persistence\Models\UserModel;
use Laravel\Sanctum\Sanctum;

beforeEach(function (): void {
    Sanctum::actingAs(new UserModel);
});

it('returns the requested user as a complete JSON API resource', function (): void {
    $user = UserModel::query()->create(['name' => 'Maria', 'email' => 'maria@example.com']);

    $this->getJson("/api/users/{$user->getKey()}")
        ->assertOk()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('data.id', (string) $user->getKey())
        ->assertJsonPath('data.type', 'users')
        ->assertJsonPath('data.attributes.name', 'Maria')
        ->assertJsonPath('data.attributes.email', 'maria@example.com')
        ->assertJsonPath('data.links.self', route('users.get', ['user' => $user->getKey()]));
});

it('returns a complete JSON API error when the user does not exist', function (): void {
    $this->getJson('/api/users/99999')
        ->assertNotFound()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '404',
            'title' => 'User não encontrado',
            'detail' => 'User 99999 não encontrado.',
        ]]]);
});

it('returns a route level JSON API error for a non numeric ID', function (): void {
    $this->getJson('/api/users/not-a-number')
        ->assertNotFound()
        ->assertExactJson(['errors' => [[
            'status' => '404',
            'title' => 'Recurso não encontrado',
            'detail' => 'O recurso solicitado não foi encontrado.',
        ]]]);
});
