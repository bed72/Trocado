<?php

declare(strict_types=1);

use Illuminate\Contracts\Debug\ExceptionHandler;
use Illuminate\Support\Facades\Route;
use Illuminate\Validation\ValidationException;
use RuntimeException as RuntimeExceptionContract;
use Symfony\Component\HttpKernel\Exception\HttpException;

it('preserves the fallback catalog and uncatalogued status codes without exposing internal details', function (int $status, string $title, string $detail): void {
    Route::get('/api/fallback-error-probe', static fn () => throw new HttpException($status, 'SQL password=private-probe'));

    $this->get('/api/fallback-error-probe', ['Accept' => 'text/html'])->assertStatus($status)
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [['title' => $title, 'detail' => $detail, 'status' => (string) $status]]]);
})->with([
    '400' => [400, 'Solicitação inválida', 'Não foi possível interpretar a solicitação.'],
    '401' => [401, 'Não autenticado', 'É necessário autenticar-se para acessar este recurso.'],
    '403' => [403, 'Acesso negado', 'Você não tem permissão para acessar este recurso.'],
    '404' => [404, 'Recurso não encontrado', 'O recurso solicitado não foi encontrado.'],
    '405' => [405, 'Método não permitido', 'O método HTTP informado não é permitido para este recurso.'],
    '406' => [406, 'Resposta não aceitável', 'Não foi possível gerar uma resposta no formato solicitado.'],
    '408' => [408, 'Tempo de solicitação esgotado', 'A solicitação excedeu o tempo limite.'],
    '409' => [409, 'Conflito', 'A solicitação entrou em conflito com o estado atual do recurso.'],
    '410' => [410, 'Recurso indisponível', 'O recurso solicitado não está mais disponível.'],
    '413' => [413, 'Conteúdo muito grande', 'O conteúdo da solicitação excede o limite permitido.'],
    '415' => [415, 'Tipo de mídia não suportado', 'O formato do conteúdo enviado não é suportado.'],
    '418 default client' => [418, 'Erro na solicitação', 'Não foi possível processar a solicitação.'],
    '419' => [419, 'Sessão expirada', 'A sessão expirou. Envie a solicitação novamente.'],
    '422' => [422, 'Dados inválidos', 'Não foi possível processar os dados enviados.'],
    '429' => [429, 'Muitas solicitações', 'O limite de solicitações foi excedido. Tente novamente mais tarde.'],
    '500' => [500, 'Erro interno do servidor', 'Não foi possível processar a solicitação.'],
    '502' => [502, 'Resposta inválida do serviço', 'Um serviço necessário retornou uma resposta inválida.'],
    '503' => [503, 'Serviço indisponível', 'O serviço está temporariamente indisponível.'],
    '504' => [504, 'Tempo de resposta esgotado', 'Um serviço necessário excedeu o tempo limite de resposta.'],
    '507 default server' => [507, 'Erro interno do servidor', 'Não foi possível processar a solicitação.'],
]);

it('keeps every validation message in field and message order with pointers', function (): void {
    Route::post('/api/validation-error-probe', static fn () => throw ValidationException::withMessages([
        'data.attributes.password' => ['Senha obrigatória.', 'Senha insuficiente.'],
        'data.attributes.email' => ['E-mail inválido.'],
    ]));

    $this->postJson('/api/validation-error-probe')->assertUnprocessable()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [
            ['title' => 'Erro de validação', 'detail' => 'Senha obrigatória.', 'status' => '422', 'source' => ['pointer' => '/data/attributes/password']],
            ['title' => 'Erro de validação', 'detail' => 'Senha insuficiente.', 'status' => '422', 'source' => ['pointer' => '/data/attributes/password']],
            ['title' => 'Erro de validação', 'detail' => 'E-mail inválido.', 'status' => '422', 'source' => ['pointer' => '/data/attributes/email']],
        ]]);
});

it('preserves functional headers and removes obsolete content length when replacing a body', function (): void {
    $this->app->make(ExceptionHandler::class)->renderable(static fn (HttpException $exception) => response('old', 429, [
        'Retry-After' => '37', 'Allow' => 'GET, HEAD', 'WWW-Authenticate' => 'Bearer',
        'Cache-Control' => 'no-store, private', 'Content-Length' => '3',
    ]));
    Route::get('/api/header-error-probe', static fn () => throw new HttpException(429));

    $response = $this->getJson('/api/header-error-probe')->assertStatus(429)
        ->assertHeader('Retry-After', '37')->assertHeader('Allow', 'GET, HEAD')
        ->assertHeader('WWW-Authenticate', 'Bearer')->assertHeader('Cache-Control', 'no-store, private')
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('errors.0.status', '429');
    expect($response->headers->has('Content-Length'))->toBeFalse();
});

it('preserves actual method rejection headers', function (): void {
    Route::get('/api/method-error-probe', static fn () => response()->noContent());

    $this->postJson('/api/method-error-probe')->assertStatus(405)->assertHeader('Allow', 'GET, HEAD')
        ->assertHeader('Content-Type', 'application/vnd.api+json')->assertJsonPath('errors.0.status', '405');
});

it('does not rewrite a ready JSON API document or its optional members and headers', function (): void {
    $body = '{"errors":[{"status":"422","title":"Query inválida","detail":"Filtro inválido.","source":{"parameter":"filter[month]"},"code":"query","meta":{"probe":true}}],"meta":{"ready":true}}';
    $this->app->make(ExceptionHandler::class)->renderable(static fn (HttpException $exception) => response($body, 422, [
        'Content-Type' => 'application/vnd.api+json; ext="https://example.invalid/probe"',
        'X-Error-Probe' => 'ready', 'Content-Length' => (string) strlen($body),
    ]));
    Route::get('/api/ready-error-probe', static fn () => throw new HttpException(422));

    $response = $this->getJson('/api/ready-error-probe')->assertUnprocessable()
        ->assertHeader('X-Error-Probe', 'ready')->assertHeader('Content-Length', (string) strlen($body))
        ->assertHeader('Content-Type', 'application/vnd.api+json; ext="https://example.invalid/probe"');
    expect($response->getContent())->toBe($body);
});

it('limits the push not found specialization to DELETE and the existing API path', function (string $method, string $path, string $title, string $detail): void {
    $this->call($method, $path, server: ['HTTP_ACCEPT' => 'application/json'])->assertNotFound()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [['status' => '404', 'title' => $title, 'detail' => $detail]]]);
})->with([
    'malformed push DELETE before controller' => ['DELETE', '/api/push-registrations/not-a-uuid', 'Registro push não encontrado', 'O registro push não foi encontrado.'],
    'unregistered API' => ['DELETE', '/api/missing-error-probe', 'Recurso não encontrado', 'O recurso solicitado não foi encontrado.'],
    'push wrong method' => ['GET', '/api/push-registrations/not-a-uuid', 'Recurso não encontrado', 'O recurso solicitado não foi encontrado.'],
]);

it('keeps Laravel JSON or HTML for a non API missing route', function (string $accept, string $type): void {
    $response = $this->get('/missing-framework-error-probe', ['Accept' => $accept])->assertNotFound();
    expect($response->headers->get('Content-Type'))->toStartWith($type);
    if ($type === 'application/json') {
        $response->assertJsonMissingPath('errors')->assertJsonStructure(['message']);
    }
})->with(['json' => ['application/json', 'application/json'], 'html' => ['text/html', 'text/html']]);

it('keeps Laravel validation JSON or redirects outside the API', function (string $accept, int $status): void {
    Route::post('/validation-framework-error-probe', static fn () => throw ValidationException::withMessages(['email' => ['E-mail obrigatório.']]))->middleware('web');

    $response = $this->from('/form-error-probe')->post('/validation-framework-error-probe', [], ['Accept' => $accept])->assertStatus($status);
    if ($status === 422) {
        $response->assertHeader('Content-Type', 'application/json')
            ->assertExactJson(['message' => 'E-mail obrigatório.', 'errors' => ['email' => ['E-mail obrigatório.']]]);
    } else {
        $response->assertRedirect('/form-error-probe')->assertSessionHasErrors(['email' => 'E-mail obrigatório.']);
    }
})->with(['json' => ['application/json', 422], 'html' => ['text/html', 302]]);

it('reports unexpected failures but not framework ignored exceptions and sanitizes even debug output', function (): void {
    $handler = $this->app->make(ExceptionHandler::class);
    $reported = [];
    $handler->reportable(function (RuntimeExceptionContract $exception) use (&$reported): bool {
        $reported[] = $exception;

        return false;
    });
    $failure = new RuntimeExceptionContract('SQL select secret password=private-probe');
    Route::get('/api/internal-error-probe', static fn () => throw $failure);
    $this->app['config']->set('app.debug', true);

    $this->getJson('/api/internal-error-probe')->assertStatus(500)
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [['title' => 'Erro interno do servidor', 'detail' => 'Não foi possível processar a solicitação.', 'status' => '500']]]);
    $handler->report(new HttpException(403));
    $handler->report(ValidationException::withMessages(['email' => 'Inválido.']));
    expect($reported)->toBe([$failure])
        ->and($handler->shouldReport($failure))->toBeTrue()
        ->and($handler->shouldReport(new HttpException(404)))->toBeFalse()
        ->and($handler->shouldReport(ValidationException::withMessages(['email' => 'Inválido.'])))->toBeFalse();
});
