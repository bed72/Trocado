<?php

declare(strict_types=1);

use App\Core\Presentation\Http\Responses\JsonErrorResponse;
use App\Notifications\Application\Exceptions\NotificationRegistrationConflictException;
use App\Notifications\Application\Exceptions\NotificationRegistrationNotFoundException;
use App\Notifications\Domain\Exceptions\InvalidNotificationRegistrationException;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return static function (Exceptions $exceptions): void {
    $exceptions->dontReport([
        NotificationRegistrationConflictException::class,
        NotificationRegistrationNotFoundException::class,
        InvalidNotificationRegistrationException::class,
    ]);

    $exceptions->render(fn (NotificationRegistrationConflictException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'Conflito de registro push',
        'detail' => $exception->getMessage(),
    ]], Response::HTTP_CONFLICT));

    $exceptions->render(fn (NotificationRegistrationNotFoundException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'Registro push não encontrado',
        'detail' => $exception->getMessage(),
    ]], Response::HTTP_NOT_FOUND));

    $exceptions->render(fn (InvalidNotificationRegistrationException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'Registro push inválido',
        'detail' => $exception->getMessage(),
        'source' => ['pointer' => "/data/attributes/{$exception->field}"],
    ]], Response::HTTP_UNPROCESSABLE_ENTITY));

    $exceptions->render(function (NotFoundHttpException $exception, Request $request): ?JsonErrorResponse {
        if (! $request->isMethod('DELETE') || ! $request->is('api/push-registrations/*')) {
            return null;
        }

        return new JsonErrorResponse([[
            'title' => 'Registro push não encontrado',
            'detail' => (new NotificationRegistrationNotFoundException)->getMessage(),
        ]], Response::HTTP_NOT_FOUND);
    });
};
