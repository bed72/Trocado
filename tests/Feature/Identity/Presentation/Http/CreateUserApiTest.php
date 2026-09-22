<?php

declare(strict_types=1);

it('rejects direct user creation as a JSON API method error without persisting', function (): void {
    $this->postJson('/api/users', [
        'data' => [
            'type' => 'users',
            'attributes' => [
                'name' => 'Maria Silva',
                'email' => 'maria.silva@example.com',
            ],
        ],
    ], [
        'Accept' => 'application/vnd.api+json',
        'Content-Type' => 'application/vnd.api+json',
    ])->assertStatus(405)
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '405',
            'title' => 'Método não permitido',
            'detail' => 'O método HTTP informado não é permitido para este recurso.',
        ]]]);

    $this->assertDatabaseCount('users', 0);
    $this->assertDatabaseCount('personal_access_tokens', 0);
});
