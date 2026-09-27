<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Controllers;

use App\Identity\Application\UseCases\VerifyEmailUseCase;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Response;

final class VerifyEmailController
{
    public function __construct(private readonly VerifyEmailUseCase $useCase) {}

    public function __invoke(int $id, string $hash): Response
    {
        if (! $this->useCase->execute(userId: $id, hash: $hash)) {
            throw new AuthorizationException;
        }

        return response()->noContent();
    }
}
