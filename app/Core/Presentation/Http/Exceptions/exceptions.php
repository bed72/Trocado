<?php

declare(strict_types=1);

use App\Core\Presentation\Http\Responses\JsonErrorResponse;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Throwable as ThrowableContract;

return static function (Exceptions $exceptions): void {
    $pageExpiredStatusCode = 419;

    $exceptions->shouldRenderJsonWhen(
        fn (Request $request): bool => $request->is('api/*') || $request->expectsJson(),
    );

    $exceptions->render(function (NotFoundHttpException $exception, Request $request): ?JsonErrorResponse {
        if (! $request->is('api/*')) {
            return null;
        }

        return new JsonErrorResponse([[
            'title' => 'Recurso não encontrado',
            'detail' => 'O recurso solicitado não foi encontrado.',
        ]], Response::HTTP_NOT_FOUND);
    });

    $exceptions->render(function (ValidationException $exception, Request $request): ?JsonErrorResponse {
        if (! $request->is('api/*')) {
            return null;
        }

        $errors = [];

        foreach ($exception->errors() as $field => $messages) {
            foreach ($messages as $message) {
                $errors[] = [
                    'detail' => $message,
                    'title' => 'Erro de validação',
                    'source' => ['pointer' => '/'.str_replace('.', '/', $field)],
                ];
            }
        }

        return new JsonErrorResponse($errors, Response::HTTP_UNPROCESSABLE_ENTITY);
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

        $response->setContent(json_encode(JsonErrorResponse::document([[
            'title' => $title,
            'detail' => $detail,
        ]], $response->getStatusCode()), JSON_THROW_ON_ERROR));
        $response->headers->set('Content-Type', 'application/vnd.api+json');
        $response->headers->remove('Content-Length');

        return $response;
    });
};
