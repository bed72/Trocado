<?php

declare(strict_types=1);

namespace App\Core\Presentation\Http\Middleware;

use App\Core\Application\Ports\ContextPort;
use App\Core\Application\Ports\UserPort;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final readonly class AuthenticatedRequestMiddleware
{
    public function __construct(
        private UserPort $userPort,
        private ContextPort $contextPort,
    ) {}

    public function handle(Request $request, Closure $next): Response
    {
        $this->contextPort->identifyUser($this->userPort->id());

        return $next($request);
    }
}
