<?php

declare(strict_types=1);

use App\Core\Presentation\Http\Responses\JsonErrorResponse;
use App\Expense\Application\Exceptions\ExpenseNotFoundException;
use App\Expense\Application\Exceptions\ExpenseOwnerNotFoundException;
use App\Expense\Application\Exceptions\InvalidExpenseCursorException;
use App\Expense\Domain\Exceptions\InvalidExpenseException;
use Illuminate\Foundation\Configuration\Exceptions;
use Symfony\Component\HttpFoundation\Response;

return static function (Exceptions $exceptions): void {
    $exceptions->dontReport(InvalidExpenseCursorException::class);

    $exceptions->render(fn (InvalidExpenseCursorException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'Cursor inválido',
        'detail' => $exception->getMessage(),
        'source' => ['pointer' => '/page/cursor'],
    ]], Response::HTTP_UNPROCESSABLE_ENTITY));

    $exceptions->render(fn (ExpenseOwnerNotFoundException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'User não encontrado',
        'detail' => $exception->getMessage(),
    ]], Response::HTTP_NOT_FOUND));

    $exceptions->render(fn (ExpenseNotFoundException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'Despesa não encontrada',
        'detail' => $exception->getMessage(),
    ]], Response::HTTP_NOT_FOUND));

    $exceptions->render(fn (InvalidExpenseException $exception): JsonErrorResponse => new JsonErrorResponse([[
        'title' => 'Dados inválidos',
        'detail' => $exception->getMessage(),
    ]], Response::HTTP_UNPROCESSABLE_ENTITY));
};
