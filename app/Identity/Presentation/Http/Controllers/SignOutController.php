<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Controllers;

use App\Identity\Application\UseCases\SignOutUseCase;
use Symfony\Component\HttpFoundation\Response;

final readonly class SignOutController
{
    public function __construct(private SignOutUseCase $useCase) {}

    public function __invoke(): Response
    {
        $this->useCase->execute();

        return response()->noContent();
    }
}
