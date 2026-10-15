<?php

declare(strict_types=1);

namespace App\Core\Presentation\Http\Middleware;

use App\Core\Application\Data\ContextInput;
use App\Core\Application\Ports\ContextPort;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

final class TraceRequestMiddleware
{
    public function __construct(private readonly ContextPort $port) {}

    public function handle(Request $request, Closure $next): Response
    {
        return $this->port->scope(function () use ($request, $next): Response {
            $traceId = (string) Str::uuid7();
            $request->attributes->set('trace_id', $traceId);

            $this->port->capture(new ContextInput(
                traceId: $traceId,
                ip: $request->ip(),
                method: $request->method(),
                path: $request->getPathInfo(),
            ));

            $response = $next($request);
            $response->headers->set('X-Request-Id', $traceId);

            return $response;
        });
    }
}
