<?php

use App\Expense\Application\Exceptions\ExpenseOwnerNotFoundException;
use App\Expense\Domain\Exceptions\InvalidExpenseException;
use App\Identity\Application\Exceptions\EmailAlreadyUsedException;
use App\Identity\Application\Exceptions\InvalidCredentialsException;
use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Domain\Exceptions\InvalidEmailException;
use App\Identity\Domain\Exceptions\InvalidNameException;
use App\Identity\Domain\Exceptions\InvalidPasswordException;
use Illuminate\Auth\Middleware\Authenticate;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Throwable as ThrowableContract;

$pageExpiredStatusCode = 419;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        health: '/up',
        commands: __DIR__.'/../routes/console.php',
        api: [
            __DIR__.'/../app/Identity/Presentation/Routes/api.php',
            __DIR__.'/../app/Expense/Presentation/Routes/api.php',
        ],
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->prependToPriorityList(before: ThrottleRequests::class, prepend: Authenticate::class);
        $middleware->trimStrings(except: [
            'data.attributes.password',
            'data.attributes.password_confirmation',
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) use ($pageExpiredStatusCode): void {
        $exceptions->dontReport([
            InvalidPasswordException::class,
            EmailAlreadyUsedException::class,
            InvalidCredentialsException::class,
        ]);

        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        $exceptions->render(fn (InvalidCredentialsException $exception) => response()->json(['errors' => [[
            'title' => 'Credenciais inválidas',
            'detail' => $exception->getMessage(),
            'status' => (string) Response::HTTP_UNAUTHORIZED,
        ]]], Response::HTTP_UNAUTHORIZED)->header('Content-Type', 'application/vnd.api+json')
        );

        $exceptions->render(fn (EmailAlreadyUsedException $exception) => response()->json(['errors' => [[
            'title' => 'E-mail já utilizado',
            'detail' => $exception->getMessage(),
            'status' => (string) Response::HTTP_CONFLICT,
            'source' => ['pointer' => '/data/attributes/email'],
        ]]], Response::HTTP_CONFLICT)->header('Content-Type', 'application/vnd.api+json')
        );

        $exceptions->render(fn (InvalidPasswordException $exception) => response()->json(['errors' => [[
            'title' => 'Dados inválidos',
            'detail' => $exception->getMessage(),
            'source' => ['pointer' => '/data/attributes/password'],
            'status' => (string) Response::HTTP_UNPROCESSABLE_ENTITY,
        ]]], Response::HTTP_UNPROCESSABLE_ENTITY)->header('Content-Type', 'application/vnd.api+json')
        );

        $exceptions->render(fn (UserNotFoundException $exception) => response()->json(['errors' => [[
            'title' => 'User não encontrado',
            'detail' => $exception->getMessage(),
            'status' => (string) Response::HTTP_NOT_FOUND,
        ]]], Response::HTTP_NOT_FOUND)->header('Content-Type', 'application/vnd.api+json')
        );

        $exceptions->render(fn (ExpenseOwnerNotFoundException $exception) => response()->json(['errors' => [[
            'title' => 'User não encontrado',
            'detail' => $exception->getMessage(),
            'status' => (string) Response::HTTP_NOT_FOUND,
        ]]], Response::HTTP_NOT_FOUND)->header('Content-Type', 'application/vnd.api+json')
        );

        $exceptions->render(fn (InvalidExpenseException $exception) => response()->json(['errors' => [[
            'title' => 'Dados inválidos',
            'detail' => $exception->getMessage(),
            'status' => (string) Response::HTTP_UNPROCESSABLE_ENTITY,
        ]]], Response::HTTP_UNPROCESSABLE_ENTITY)->header('Content-Type', 'application/vnd.api+json')
        );

        $exceptions->render(fn (EmailAlreadyUsedException $exception) => response()->json(['errors' => [[
            'title' => 'E-mail já utilizado',
            'detail' => $exception->getMessage(),
            'status' => (string) Response::HTTP_CONFLICT,
        ]]], Response::HTTP_CONFLICT)->header('Content-Type', 'application/vnd.api+json')
        );

        $exceptions->render(fn (InvalidEmailException $exception) => response()->json(['errors' => [[
            'title' => 'Dados inválidos',
            'detail' => $exception->getMessage(),
            'status' => (string) Response::HTTP_UNPROCESSABLE_ENTITY,
        ]]], Response::HTTP_UNPROCESSABLE_ENTITY)->header('Content-Type', 'application/vnd.api+json')
        );

        $exceptions->render(fn (InvalidNameException $exception) => response()->json(['errors' => [[
            'title' => 'Dados inválidos',
            'detail' => $exception->getMessage(),
            'status' => (string) Response::HTTP_UNPROCESSABLE_ENTITY,
        ]]], Response::HTTP_UNPROCESSABLE_ENTITY)->header('Content-Type', 'application/vnd.api+json')
        );

        $exceptions->render(function (NotFoundHttpException $exception, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            return response()->json(['errors' => [[
                'title' => 'Recurso não encontrado',
                'status' => (string) Response::HTTP_NOT_FOUND,
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
                        'detail' => $message,
                        'title' => 'Erro de validação',
                        'status' => (string) Response::HTTP_UNPROCESSABLE_ENTITY,
                        'source' => ['pointer' => '/'.str_replace('.', '/', $field)],
                    ];
                }
            }

            return response()->json(['errors' => $errors], Response::HTTP_UNPROCESSABLE_ENTITY)
                ->header('Content-Type', 'application/vnd.api+json');
        });

        $exceptions->respond(function (Response $response, ThrowableContract $exception, Request $request) use ($pageExpiredStatusCode): Response {
            if (! $request->is('api/*') || str_starts_with(
                (string) $response->headers->get('Content-Type'),
                'application/vnd.api+json',
            )) {
                return $response;
            }

            [$title, $detail] = match ($response->getStatusCode()) {
                $pageExpiredStatusCode => ['Sessão expirada', 'A sessão expirou. Envie a solicitação novamente.'],
                Response::HTTP_GONE => ['Recurso indisponível', 'O recurso solicitado não está mais disponível.'],
                Response::HTTP_FORBIDDEN => ['Acesso negado', 'Você não tem permissão para acessar este recurso.'],
                Response::HTTP_NOT_FOUND => ['Recurso não encontrado', 'O recurso solicitado não foi encontrado.'],
                Response::HTTP_BAD_REQUEST => ['Solicitação inválida', 'Não foi possível interpretar a solicitação.'],
                Response::HTTP_CONFLICT => ['Conflito', 'A solicitação entrou em conflito com o estado atual do recurso.'],
                Response::HTTP_UNAUTHORIZED => ['Não autenticado', 'É necessário autenticar-se para acessar este recurso.'],
                Response::HTTP_UNPROCESSABLE_ENTITY => ['Dados inválidos', 'Não foi possível processar os dados enviados.'],
                Response::HTTP_REQUEST_TIMEOUT => ['Tempo de solicitação esgotado', 'A solicitação excedeu o tempo limite.'],
                Response::HTTP_SERVICE_UNAVAILABLE => ['Serviço indisponível', 'O serviço está temporariamente indisponível.'],
                Response::HTTP_INTERNAL_SERVER_ERROR => ['Erro interno do servidor', 'Não foi possível processar a solicitação.'],
                Response::HTTP_BAD_GATEWAY => ['Resposta inválida do serviço', 'Um serviço necessário retornou uma resposta inválida.'],
                Response::HTTP_NOT_ACCEPTABLE => ['Resposta não aceitável', 'Não foi possível gerar uma resposta no formato solicitado.'],
                Response::HTTP_UNSUPPORTED_MEDIA_TYPE => ['Tipo de mídia não suportado', 'O formato do conteúdo enviado não é suportado.'],
                Response::HTTP_METHOD_NOT_ALLOWED => ['Método não permitido', 'O método HTTP informado não é permitido para este recurso.'],
                Response::HTTP_REQUEST_ENTITY_TOO_LARGE => ['Conteúdo muito grande', 'O conteúdo da solicitação excede o limite permitido.'],
                Response::HTTP_GATEWAY_TIMEOUT => ['Tempo de resposta esgotado', 'Um serviço necessário excedeu o tempo limite de resposta.'],
                Response::HTTP_TOO_MANY_REQUESTS => ['Muitas solicitações', 'O limite de solicitações foi excedido. Tente novamente mais tarde.'],
                default => $response->isServerError()
                    ? ['Erro interno do servidor', 'Não foi possível processar a solicitação.']
                    : ['Erro na solicitação', 'Não foi possível processar a solicitação.'],
            };

            $response->setContent(json_encode(['errors' => [[
                'title' => $title,
                'detail' => $detail,
                'status' => (string) $response->getStatusCode(),
            ]]], JSON_THROW_ON_ERROR));
            $response->headers->set('Content-Type', 'application/vnd.api+json');
            $response->headers->remove('Content-Length');

            return $response;
        });
    })->create();
