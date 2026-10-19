<?php

declare(strict_types=1);

use App\Core\Presentation\Http\Responses\JsonErrorResponse;

it('builds a single error with a textual HTTP status and no success envelope or implicit optional members', function (int $status): void {
    $response = new JsonErrorResponse([['title' => 'Erro público', 'detail' => 'Detalhe público.']], $status);

    expect($response->getStatusCode())->toBe($status)
        ->and($response->headers->get('Content-Type'))->toBe('application/vnd.api+json')
        ->and($response->getData(true))->toBe(['errors' => [[
            'title' => 'Erro público', 'detail' => 'Detalhe público.', 'status' => (string) $status,
        ]]])
        ->and($response->getData(true))->not->toHaveKey('data');
})->with([401, 403, 404, 409, 418, 419, 422, 429, 500, 507]);

it('preserves error order multiplicity and each optional source without reclassifying pointers', function (): void {
    $response = new JsonErrorResponse([
        ['title' => 'Validação', 'detail' => 'Primeira mensagem.', 'source' => ['pointer' => '/data/attributes/password']],
        ['title' => 'Validação', 'detail' => 'Segunda mensagem.', 'source' => ['pointer' => '/data/attributes/password']],
        ['title' => 'Cursor', 'detail' => 'Cursor inválido.', 'source' => ['pointer' => '/page/cursor']],
        ['title' => 'Query', 'detail' => 'Mês inválido.', 'source' => ['parameter' => 'filter[month]']],
    ], 422);

    expect($response->getData(true))->toBe(['errors' => [
        ['title' => 'Validação', 'detail' => 'Primeira mensagem.', 'source' => ['pointer' => '/data/attributes/password'], 'status' => '422'],
        ['title' => 'Validação', 'detail' => 'Segunda mensagem.', 'source' => ['pointer' => '/data/attributes/password'], 'status' => '422'],
        ['title' => 'Cursor', 'detail' => 'Cursor inválido.', 'source' => ['pointer' => '/page/cursor'], 'status' => '422'],
        ['title' => 'Query', 'detail' => 'Mês inválido.', 'source' => ['parameter' => 'filter[month]'], 'status' => '422'],
    ]]);
});

it('preserves caller supplied optional error members and literal Unicode text', function (): void {
    $response = new JsonErrorResponse([[
        'title' => 'E-mail já utilizado',
        'detail' => 'Não foi possível utilizar o e-mail informado.',
        'id' => 'error-probe',
        'code' => 'email-conflict',
        'links' => ['about' => 'https://example.invalid/errors/email'],
        'source' => ['pointer' => '/data/attributes/email'],
        'meta' => ['retryable' => false, 'attempt' => 1],
    ]], 409);

    expect($response->getData(true))->toBe(['errors' => [[
        'title' => 'E-mail já utilizado',
        'detail' => 'Não foi possível utilizar o e-mail informado.',
        'id' => 'error-probe',
        'code' => 'email-conflict',
        'links' => ['about' => 'https://example.invalid/errors/email'],
        'source' => ['pointer' => '/data/attributes/email'],
        'meta' => ['retryable' => false, 'attempt' => 1],
        'status' => '409',
    ]]]);
});

it('exposes the same document independently of response construction without mutating the input', function (): void {
    $errors = [
        ['title' => 'Primeiro', 'detail' => 'Primeiro detalhe.'],
        ['title' => 'Segundo', 'detail' => 'Segundo detalhe.', 'source' => ['pointer' => '/data/attributes/name']],
    ];
    $document = JsonErrorResponse::document($errors, 422);

    expect($document)->toBe(['errors' => [
        ['title' => 'Primeiro', 'detail' => 'Primeiro detalhe.', 'status' => '422'],
        ['title' => 'Segundo', 'detail' => 'Segundo detalhe.', 'source' => ['pointer' => '/data/attributes/name'], 'status' => '422'],
    ]])
        ->and($document)->toBe((new JsonErrorResponse($errors, 422))->getData(true))
        ->and($errors)->toBe([
            ['title' => 'Primeiro', 'detail' => 'Primeiro detalhe.'],
            ['title' => 'Segundo', 'detail' => 'Segundo detalhe.', 'source' => ['pointer' => '/data/attributes/name']],
        ]);
});
