<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Responses;

use Illuminate\Http\JsonResponse;
use Symfony\Component\HttpFoundation\Response;

final class PasswordRecoveryResponse extends JsonResponse
{
    public function __construct()
    {
        parent::__construct([
            'meta' => ['message' => 'Se a conta estiver apta, enviaremos as instruções de recuperação.'],
        ], Response::HTTP_ACCEPTED, ['Content-Type' => 'application/vnd.api+json']);
    }
}
