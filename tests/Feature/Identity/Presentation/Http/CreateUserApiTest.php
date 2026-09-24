<?php

declare(strict_types=1);

it('rejects direct user creation as a missing JSON API endpoint without persisting', function (): void {
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
    ])->assertNotFound()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '404',
            'title' => 'Recurso não encontrado',
            'detail' => 'O recurso solicitado não foi encontrado.',
        ]]]);

    $this->assertDatabaseCount('users', 0);
    $this->assertDatabaseCount('personal_access_tokens', 0);
});
