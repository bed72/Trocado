<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Middleware;

use App\Identity\Application\Exceptions\InactiveUserException;
use App\Identity\Application\Ports\UserPort;
use App\Identity\Domain\Enums\UserStatusEnum;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final readonly class EnsureActiveUserMiddleware
{
    public function __construct(private UserPort $port) {}

    public function handle(Request $request, Closure $next): Response
    {
        $status = $this->port->status();

        if ($status !== UserStatusEnum::Active) {
            throw new InactiveUserException(status: $status);
        }

        return $next($request);
    }
}
