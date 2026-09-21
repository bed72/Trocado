<?php

use App\Budget\Application\Exceptions\BudgetNotFoundException;
use App\Budget\Application\Exceptions\BudgetRecurrenceNotFoundException;
use App\Budget\Domain\Exceptions\InvalidBudgetDateRangeException;
use App\Budget\Domain\Exceptions\InvalidBudgetRecurrenceException;
use App\Budget\Domain\Exceptions\InvalidMoneyAmountException;
use App\Budget\Domain\Exceptions\InvalidRecurrenceTransitionException;
use App\Budget\Domain\Exceptions\OverlappingBudgetException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: [
            __DIR__.'/../app/Budget/Presentation/Routes/api.php',
        ],
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        $exceptions->render(function (BudgetNotFoundException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => '404',
                'title' => 'Budget não encontrado',
                'detail' => $exception->getMessage(),
            ]]], 404)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (BudgetRecurrenceNotFoundException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => '404',
                'title' => 'Recorrência não encontrada',
                'detail' => $exception->getMessage(),
            ]]], 404)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (InvalidBudgetDateRangeException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => '422',
                'title' => 'Dados inválidos',
                'detail' => $exception->getMessage(),
            ]]], 422)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (InvalidMoneyAmountException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => '422',
                'title' => 'Dados inválidos',
                'detail' => $exception->getMessage(),
            ]]], 422)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (InvalidBudgetRecurrenceException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => '422',
                'title' => 'Dados inválidos',
                'detail' => $exception->getMessage(),
            ]]], 422)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (OverlappingBudgetException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => '409',
                'title' => 'Conflito de datas',
                'detail' => $exception->getMessage(),
            ]]], 409)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (InvalidRecurrenceTransitionException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => '409',
                'title' => 'Transição de recorrência inválida',
                'detail' => $exception->getMessage(),
            ]]], 409)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (NotFoundHttpException $exception, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            return response()->json(['errors' => [[
                'status' => '404',
                'title' => 'Recurso não encontrado',
                'detail' => 'O recurso solicitado não foi encontrado.',
            ]]], 404)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (ValidationException $exception, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            $errors = [];

            foreach ($exception->errors() as $field => $messages) {
                foreach ($messages as $message) {
                    $errors[] = [
                        'status' => '422',
                        'title' => 'Erro de validação',
                        'detail' => $message,
                        'source' => ['pointer' => '/'.str_replace('.', '/', $field)],
                    ];
                }
            }

            return response()->json(['errors' => $errors], 422)
                ->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->respond(function (Response $response, Throwable $exception, Request $request): Response {
            if (! $request->is('api/*') || str_starts_with(
                (string) $response->headers->get('Content-Type'),
                'application/vnd.api+json',
            )) {
                return $response;
            }

            [$title, $detail] = match ($response->getStatusCode()) {
                400 => ['Solicitação inválida', 'Não foi possível interpretar a solicitação.'],
                401 => ['Não autenticado', 'É necessário autenticar-se para acessar este recurso.'],
                403 => ['Acesso negado', 'Você não tem permissão para acessar este recurso.'],
                404 => ['Recurso não encontrado', 'O recurso solicitado não foi encontrado.'],
                405 => ['Método não permitido', 'O método HTTP informado não é permitido para este recurso.'],
                406 => ['Resposta não aceitável', 'Não foi possível gerar uma resposta no formato solicitado.'],
                408 => ['Tempo de solicitação esgotado', 'A solicitação excedeu o tempo limite.'],
                409 => ['Conflito', 'A solicitação entrou em conflito com o estado atual do recurso.'],
                410 => ['Recurso indisponível', 'O recurso solicitado não está mais disponível.'],
                413 => ['Conteúdo muito grande', 'O conteúdo da solicitação excede o limite permitido.'],
                415 => ['Tipo de mídia não suportado', 'O formato do conteúdo enviado não é suportado.'],
                419 => ['Sessão expirada', 'A sessão expirou. Envie a solicitação novamente.'],
                422 => ['Dados inválidos', 'Não foi possível processar os dados enviados.'],
                429 => ['Muitas solicitações', 'O limite de solicitações foi excedido. Tente novamente mais tarde.'],
                500 => ['Erro interno do servidor', 'Não foi possível processar a solicitação.'],
                502 => ['Resposta inválida do serviço', 'Um serviço necessário retornou uma resposta inválida.'],
                503 => ['Serviço indisponível', 'O serviço está temporariamente indisponível.'],
                504 => ['Tempo de resposta esgotado', 'Um serviço necessário excedeu o tempo limite de resposta.'],
                default => $response->isServerError()
                    ? ['Erro interno do servidor', 'Não foi possível processar a solicitação.']
                    : ['Erro na solicitação', 'Não foi possível processar a solicitação.'],
            };

            $response->setContent(json_encode(['errors' => [[
                'status' => (string) $response->getStatusCode(),
                'title' => $title,
                'detail' => $detail,
            ]]], JSON_THROW_ON_ERROR));
            $response->headers->set('Content-Type', 'application/vnd.api+json');
            $response->headers->remove('Content-Length');

            return $response;
        });
    })->create();
