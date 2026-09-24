<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Route;

it('normalizes HTTP errors as JSON API responses', function (): void {
    $this->postJson('/api/users')
        ->assertStatus(405)
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '405',
            'title' => 'Método não permitido',
            'detail' => 'O método HTTP informado não é permitido para este recurso.',
        ]]]);
});

it('normalizes internal errors without exposing sensitive details', function (): void {
    Route::get('/api/failing-endpoint', static function (): never {
        throw new RuntimeException('Detalhes internos sensíveis.');
    });

    $this->getJson('/api/failing-endpoint')
        ->assertInternalServerError()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '500',
            'title' => 'Erro interno do servidor',
            'detail' => 'Não foi possível processar a solicitação.',
        ]]]);
});
