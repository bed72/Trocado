<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Middleware;

use App\Identity\Application\UseCases\ExtendSessionUseCase;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final readonly class ExtendSessionMiddleware
{
    public function __construct(private ExtendSessionUseCase $useCase) {}

    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        if ($response->isSuccessful()) {
            $this->useCase->execute();
        }

        return $response;
    }
}
