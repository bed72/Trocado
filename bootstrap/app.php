<?php

use App\Authentication\Application\Exceptions\InvalidCredentialsException;
use App\Authentication\Application\Exceptions\SignUpEmailAlreadyUsedException;
use App\Authentication\Domain\Exceptions\InvalidPasswordException;
use App\Budget\Application\Exceptions\BudgetNotFoundException;
use App\Budget\Application\Exceptions\BudgetRecurrenceNotFoundException;
use App\Budget\Domain\Exceptions\InvalidBudgetDateRangeException;
use App\Budget\Domain\Exceptions\InvalidBudgetRecurrenceException;
use App\Budget\Domain\Exceptions\InvalidMoneyAmountException;
use App\Budget\Domain\Exceptions\InvalidRecurrenceTransitionException;
use App\Budget\Domain\Exceptions\OverlappingBudgetException;
use App\User\Application\Exceptions\EmailAlreadyUsedException;
use App\User\Application\Exceptions\UserNotFoundException;
use App\User\Domain\Exceptions\InvalidEmailException;
use App\User\Domain\Exceptions\InvalidUserNameException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Throwable as BaseThrowable;

$pageExpiredStatusCode = 419;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: [
            __DIR__.'/../app/Authentication/Presentation/Routes/api.php',
            __DIR__.'/../app/Budget/Presentation/Routes/api.php',
            __DIR__.'/../app/User/Presentation/Routes/api.php',
        ],
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->trimStrings(except: [
            'data.attributes.password',
            'data.attributes.password_confirmation',
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) use ($pageExpiredStatusCode): void {
        $exceptions->dontReport([
            InvalidCredentialsException::class,
            SignUpEmailAlreadyUsedException::class,
            InvalidPasswordException::class,
        ]);

        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        $exceptions->render(function (InvalidCredentialsException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_UNAUTHORIZED,
                'title' => 'Credenciais inválidas',
                'detail' => $exception->getMessage(),
            ]]], Response::HTTP_UNAUTHORIZED)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (SignUpEmailAlreadyUsedException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_CONFLICT,
                'title' => 'E-mail já utilizado',
                'detail' => $exception->getMessage(),
                'source' => ['pointer' => '/data/attributes/email'],
            ]]], Response::HTTP_CONFLICT)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (InvalidPasswordException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_UNPROCESSABLE_ENTITY,
                'title' => 'Dados inválidos',
                'detail' => $exception->getMessage(),
                'source' => ['pointer' => '/data/attributes/password'],
            ]]], Response::HTTP_UNPROCESSABLE_ENTITY)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (BudgetNotFoundException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_NOT_FOUND,
                'title' => 'Budget não encontrado',
                'detail' => $exception->getMessage(),
            ]]], Response::HTTP_NOT_FOUND)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (BudgetRecurrenceNotFoundException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_NOT_FOUND,
                'title' => 'Recorrência não encontrada',
                'detail' => $exception->getMessage(),
            ]]], Response::HTTP_NOT_FOUND)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (InvalidBudgetDateRangeException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_UNPROCESSABLE_ENTITY,
                'title' => 'Dados inválidos',
                'detail' => $exception->getMessage(),
            ]]], Response::HTTP_UNPROCESSABLE_ENTITY)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (InvalidMoneyAmountException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_UNPROCESSABLE_ENTITY,
                'title' => 'Dados inválidos',
                'detail' => $exception->getMessage(),
            ]]], Response::HTTP_UNPROCESSABLE_ENTITY)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (InvalidBudgetRecurrenceException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_UNPROCESSABLE_ENTITY,
                'title' => 'Dados inválidos',
                'detail' => $exception->getMessage(),
            ]]], Response::HTTP_UNPROCESSABLE_ENTITY)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (OverlappingBudgetException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_CONFLICT,
                'title' => 'Conflito de datas',
                'detail' => $exception->getMessage(),
            ]]], Response::HTTP_CONFLICT)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (InvalidRecurrenceTransitionException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_CONFLICT,
                'title' => 'Transição de recorrência inválida',
                'detail' => $exception->getMessage(),
            ]]], Response::HTTP_CONFLICT)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (UserNotFoundException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_NOT_FOUND,
                'title' => 'User não encontrado',
                'detail' => $exception->getMessage(),
            ]]], Response::HTTP_NOT_FOUND)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (EmailAlreadyUsedException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_CONFLICT,
                'title' => 'E-mail já utilizado',
                'detail' => $exception->getMessage(),
            ]]], Response::HTTP_CONFLICT)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (InvalidEmailException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_UNPROCESSABLE_ENTITY,
                'title' => 'Dados inválidos',
                'detail' => $exception->getMessage(),
            ]]], Response::HTTP_UNPROCESSABLE_ENTITY)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (InvalidUserNameException $exception, Request $request) {
            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_UNPROCESSABLE_ENTITY,
                'title' => 'Dados inválidos',
                'detail' => $exception->getMessage(),
            ]]], Response::HTTP_UNPROCESSABLE_ENTITY)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (NotFoundHttpException $exception, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            return response()->json(['errors' => [[
                'status' => (string) Response::HTTP_NOT_FOUND,
                'title' => 'Recurso não encontrado',
                'detail' => 'O recurso solicitado não foi encontrado.',
            ]]], Response::HTTP_NOT_FOUND)->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->render(function (ValidationException $exception, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            $errors = [];

            foreach ($exception->errors() as $field => $messages) {
                foreach ($messages as $message) {
                    $errors[] = [
                        'status' => (string) Response::HTTP_UNPROCESSABLE_ENTITY,
                        'title' => 'Erro de validação',
                        'detail' => $message,
                        'source' => ['pointer' => '/'.str_replace('.', '/', $field)],
                    ];
                }
            }

            return response()->json(['errors' => $errors], Response::HTTP_UNPROCESSABLE_ENTITY)
                ->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->respond(function (Response $response, BaseThrowable $exception, Request $request) use ($pageExpiredStatusCode): Response {
            if (! $request->is('api/*') || str_starts_with(
                (string) $response->headers->get('Content-Type'),
                'application/vnd.api+json',
            )) {
                return $response;
            }

            [$title, $detail] = match ($response->getStatusCode()) {
                Response::HTTP_BAD_REQUEST => ['Solicitação inválida', 'Não foi possível interpretar a solicitação.'],
                Response::HTTP_UNAUTHORIZED => ['Não autenticado', 'É necessário autenticar-se para acessar este recurso.'],
                Response::HTTP_FORBIDDEN => ['Acesso negado', 'Você não tem permissão para acessar este recurso.'],
                Response::HTTP_NOT_FOUND => ['Recurso não encontrado', 'O recurso solicitado não foi encontrado.'],
                Response::HTTP_METHOD_NOT_ALLOWED => ['Método não permitido', 'O método HTTP informado não é permitido para este recurso.'],
                Response::HTTP_NOT_ACCEPTABLE => ['Resposta não aceitável', 'Não foi possível gerar uma resposta no formato solicitado.'],
                Response::HTTP_REQUEST_TIMEOUT => ['Tempo de solicitação esgotado', 'A solicitação excedeu o tempo limite.'],
                Response::HTTP_CONFLICT => ['Conflito', 'A solicitação entrou em conflito com o estado atual do recurso.'],
                Response::HTTP_GONE => ['Recurso indisponível', 'O recurso solicitado não está mais disponível.'],
                Response::HTTP_REQUEST_ENTITY_TOO_LARGE => ['Conteúdo muito grande', 'O conteúdo da solicitação excede o limite permitido.'],
                Response::HTTP_UNSUPPORTED_MEDIA_TYPE => ['Tipo de mídia não suportado', 'O formato do conteúdo enviado não é suportado.'],
                $pageExpiredStatusCode => ['Sessão expirada', 'A sessão expirou. Envie a solicitação novamente.'],
                Response::HTTP_UNPROCESSABLE_ENTITY => ['Dados inválidos', 'Não foi possível processar os dados enviados.'],
                Response::HTTP_TOO_MANY_REQUESTS => ['Muitas solicitações', 'O limite de solicitações foi excedido. Tente novamente mais tarde.'],
                Response::HTTP_INTERNAL_SERVER_ERROR => ['Erro interno do servidor', 'Não foi possível processar a solicitação.'],
                Response::HTTP_BAD_GATEWAY => ['Resposta inválida do serviço', 'Um serviço necessário retornou uma resposta inválida.'],
                Response::HTTP_SERVICE_UNAVAILABLE => ['Serviço indisponível', 'O serviço está temporariamente indisponível.'],
                Response::HTTP_GATEWAY_TIMEOUT => ['Tempo de resposta esgotado', 'Um serviço necessário excedeu o tempo limite de resposta.'],
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
