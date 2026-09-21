<?php

declare(strict_types=1);

use App\User\Infrastructure\Persistence\Models\UserModel;

it('returns an empty JSON API user collection', function (): void {
    $this->getJson(route('users.get-all'))
        ->assertOk()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['data' => []]);
});

it('lists users in identifier order', function (): void {
    $first = UserModel::query()->create(['name' => 'Maria', 'email' => 'maria@example.com']);
    $second = UserModel::query()->create(['name' => 'João', 'email' => 'joao@example.com']);

    $this->getJson(route('users.get-all'))
        ->assertOk()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonCount(2, 'data')
        ->assertJsonPath('data.0.id', (string) $first->getKey())
        ->assertJsonPath('data.0.attributes.email', 'maria@example.com')
        ->assertJsonPath('data.1.id', (string) $second->getKey())
        ->assertJsonPath('data.1.attributes.email', 'joao@example.com');
});
