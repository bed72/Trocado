<?php

declare(strict_types=1);

use App\Core\Presentation\Http\Middleware\AuthenticatedRequestMiddleware;
use App\Core\Presentation\Http\Middleware\TraceRequestMiddleware;
use App\Identity\Presentation\Http\Middleware\EnsureActiveUserMiddleware;
use App\Identity\Presentation\Http\Middleware\ExtendSessionMiddleware;
use Illuminate\Auth\Middleware\Authenticate;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Routing\Middleware\ThrottleRequests;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        health: '/up',
        commands: __DIR__.'/../routes/console.php',
        api: [
            __DIR__.'/../app/Expense/Presentation/Routes/api.php',
            __DIR__.'/../app/Metrics/Presentation/Routes/api.php',
            __DIR__.'/../app/Insights/Presentation/Routes/api.php',
            __DIR__.'/../app/Identity/Presentation/Routes/api.php',
            __DIR__.'/../app/Notifications/Presentation/Routes/api.php',
        ],
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->redirectGuestsTo(fn (Request $request): ?string => $request->is('api/*') ? null : route('login'));
        $middleware->append(TraceRequestMiddleware::class);
        $middleware->alias([
            'user.active' => EnsureActiveUserMiddleware::class,
            'session.extend' => ExtendSessionMiddleware::class,
            'request.authenticated' => AuthenticatedRequestMiddleware::class,
        ]);
        $middleware->prependToPriorityList(before: ThrottleRequests::class, prepend: Authenticate::class);
        $middleware->prependToPriorityList(
            prepend: AuthenticatedRequestMiddleware::class,
            before: [ThrottleRequests::class, SubstituteBindings::class],
        );
        $middleware->trimStrings(except: [
            'data.id',
            'data.attributes.token',
            'data.attributes.password',
            'data.attributes.installation_id',
            'data.attributes.password_confirmation',
            'data.attributes.registration_identifier',
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        (require __DIR__.'/../app/Identity/Presentation/Http/Exceptions/exceptions.php')($exceptions);
        (require __DIR__.'/../app/Expense/Presentation/Http/Exceptions/exceptions.php')($exceptions);
        (require __DIR__.'/../app/Notifications/Presentation/Http/Exceptions/exceptions.php')($exceptions);
        (require __DIR__.'/../app/Core/Presentation/Http/Exceptions/exceptions.php')($exceptions);
    })->create();
