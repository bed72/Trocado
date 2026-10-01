<?php

declare(strict_types=1);

namespace App\Core\Presentation\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Laravel\Nightwatch\Core;
use Symfony\Component\HttpFoundation\Response;

final class AssignRequestIdMiddleware
{
    public function __construct(private readonly Core $nightwatch) {}

    public function handle(Request $request, Closure $next): Response
    {
        if ($request->is('api/email-verification/*')) {
            $this->nightwatch->executionState->executionPreview = $request->method().' /api/email-verification/[redacted]/[redacted]';
        }

        $requestId = (string) Str::uuid();
        $request->attributes->set('request_id', $requestId);

        Log::shareContext(['request_id' => $requestId]);

        try {
            $response = $next($request);
            $response->headers->set('X-Request-Id', $requestId);

            return $response;
        } finally {
            Log::withoutContext(['request_id']);
            Log::flushSharedContext();
        }
    }
}
