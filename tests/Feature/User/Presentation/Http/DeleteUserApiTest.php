<?php

declare(strict_types=1);

use App\User\Infrastructure\Persistence\Models\UserModel;
use Laravel\Sanctum\Sanctum;

beforeEach(function (): void {
    Sanctum::actingAs(new UserModel);
});

it('deletes a user and it can no longer be retrieved', function (): void {
    $user = UserModel::query()->create(['name' => 'Maria', 'email' => 'maria@example.com']);

    $this->deleteJson("/api/users/{$user->getKey()}")->assertNoContent();

    $this->assertDatabaseMissing('users', ['id' => $user->getKey()]);
    $this->getJson("/api/users/{$user->getKey()}")
        ->assertNotFound()
        ->assertJsonPath('errors.0.status', '404');
});

it('returns a complete JSON API error when the user does not exist', function (): void {
    $this->deleteJson('/api/users/99999')
        ->assertNotFound()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '404',
            'title' => 'User não encontrado',
            'detail' => 'User 99999 não encontrado.',
        ]]]);
});

it('returns a route level JSON API error for a non numeric ID', function (): void {
    $this->deleteJson('/api/users/not-a-number')
        ->assertNotFound()
        ->assertExactJson(['errors' => [[
            'status' => '404',
            'title' => 'Recurso não encontrado',
            'detail' => 'O recurso solicitado não foi encontrado.',
        ]]]);
});
