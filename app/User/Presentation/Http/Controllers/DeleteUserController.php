<?php

declare(strict_types=1);

namespace App\User\Presentation\Http\Controllers;

use App\User\Application\UseCases\DeleteUserUseCase;
use Illuminate\Http\Response;

final class DeleteUserController
{
    public function __construct(private readonly DeleteUserUseCase $useCase) {}

    public function __invoke(int $user): Response
    {
        $this->useCase->execute(id: $user);

        return response()->noContent();
    }
}
