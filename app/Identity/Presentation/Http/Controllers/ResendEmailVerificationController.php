<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Controllers;

use App\Identity\Application\UseCases\ResendEmailVerificationUseCase;
use App\Identity\Presentation\Http\Requests\ResendEmailVerificationRequest;
use Symfony\Component\HttpFoundation\Response;

final class ResendEmailVerificationController
{
    public function __construct(private readonly ResendEmailVerificationUseCase $useCase) {}

    public function __invoke(ResendEmailVerificationRequest $request): Response
    {
        $this->useCase->execute(
            email: $request->validated(key: 'data.attributes.email'),
        );

        return response()->noContent(status: Response::HTTP_ACCEPTED);
    }
}
