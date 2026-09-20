<?php

use App\Budget\Application\Exceptions\BudgetNotFoundException;
use App\Budget\Domain\Exceptions\InvalidBudgetDateRangeException;
use App\Budget\Domain\Exceptions\InvalidMoneyAmountException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: __DIR__.'/../routes/api.php',
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

        $exceptions->render(function (NotFoundHttpException $exception, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            return response()->json(['errors' => [[
                'status' => '404',
                'title' => 'Recurso não encontrado',
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
    })->create();
