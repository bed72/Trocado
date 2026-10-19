<?php

declare(strict_types=1);

use App\Core\Presentation\Http\Responses\JsonErrorResponse;
use App\Identity\Application\Exceptions\EmailAlreadyUsedException;
use App\Identity\Application\Exceptions\InactiveUserException;
use App\Identity\Application\Exceptions\InvalidCredentialsException;
use App\Identity\Application\Exceptions\UnverifiedEmailException;
use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Domain\Exceptions\InvalidAvatarException;
use App\Identity\Domain\Exceptions\InvalidEmailException;
use App\Identity\Domain\Exceptions\InvalidNameException;
use App\Identity\Domain\Exceptions\InvalidPasswordException;
use Illuminate\Foundation\Configuration\Exceptions;
use Symfony\Component\HttpFoundation\Response;

return static function (Exceptions $exceptions): void {
    $exceptions->dontReport([
        InactiveUserException::class,
        InvalidPasswordException::class,
        EmailAlreadyUsedException::class,
        InvalidCredentialsException::class,
        UnverifiedEmailException::class,
    ]);

    $exceptions->render(fn (InvalidCredentialsException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'Credenciais inválidas',
        'detail' => $exception->getMessage(),
    ]], Response::HTTP_UNAUTHORIZED));

    $exceptions->render(fn (UnverifiedEmailException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'E-mail não confirmado',
        'detail' => $exception->getMessage(),
    ]], Response::HTTP_FORBIDDEN));

    $exceptions->render(function (InactiveUserException $exception): JsonErrorResponse {
        [$title, $detail] = match ($exception->status) {
            UserStatusEnum::Blocked => ['Conta bloqueada', 'A conta está bloqueada.'],
            UserStatusEnum::Pending => ['Conta pendente', 'A conta aguarda ativação.'],
            UserStatusEnum::Active => ['Acesso negado', 'A conta não está disponível.'],
        };

        return new JsonErrorResponse([[
            'title' => $title,
            'detail' => $detail,
        ]], Response::HTTP_FORBIDDEN);
    });

    $exceptions->render(fn (EmailAlreadyUsedException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'E-mail já utilizado',
        'detail' => $exception->getMessage(),
        'source' => ['pointer' => '/data/attributes/email'],
    ]], Response::HTTP_CONFLICT));

    $exceptions->render(fn (InvalidPasswordException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'Dados inválidos',
        'detail' => $exception->getMessage(),
        'source' => ['pointer' => '/data/attributes/password'],
    ]], Response::HTTP_UNPROCESSABLE_ENTITY));

    $exceptions->render(fn (UserNotFoundException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'User não encontrado',
        'detail' => $exception->getMessage(),
    ]], Response::HTTP_NOT_FOUND));

    $exceptions->render(fn (InvalidEmailException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'Dados inválidos',
        'detail' => $exception->getMessage(),
    ]], Response::HTTP_UNPROCESSABLE_ENTITY));

    $exceptions->render(fn (InvalidAvatarException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'Dados inválidos',
        'detail' => $exception->getMessage(),
        'source' => ['pointer' => '/data/attributes/avatar'],
    ]], Response::HTTP_UNPROCESSABLE_ENTITY));

    $exceptions->render(fn (InvalidNameException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'Dados inválidos',
        'detail' => $exception->getMessage(),
    ]], Response::HTTP_UNPROCESSABLE_ENTITY));
};
