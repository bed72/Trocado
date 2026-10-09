<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Adapters;

use App\Core\Application\Data\ContextInput;
use App\Core\Application\Ports\ContextPort;
use Illuminate\Log\Context\Repository as ContextRepository;

use function is_string;

final readonly class ContextAdapter implements ContextPort
{
    public function __construct(private ContextRepository $context) {}

    public function scope(callable $operation): mixed
    {
        return $this->context->scope($operation);
    }

    public function identifyRoute(string $route): void
    {
        $this->context->add('route', $route);
    }

    public function identifyUser(int $userId): void
    {
        $this->context->add('user_id', $userId);
    }

    public function traceId(): ?string
    {
        $traceId = $this->context->get('trace_id');

        return is_string($traceId) ? $traceId : null;
    }

    public function capture(ContextInput $input): void
    {
        $this->context->add([
            'ip' => $input->ip,
            'path' => $input->path,
            'trace_id' => $input->traceId,
            'request_id' => $input->traceId,
            'http_method' => $input->method,
        ]);
    }
}
