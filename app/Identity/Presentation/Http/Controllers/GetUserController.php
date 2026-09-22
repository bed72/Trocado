<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Controllers;

use App\Identity\Application\UseCases\GetUserUseCase;
use App\Identity\Presentation\Http\Responses\UserResponse;

final class GetUserController
{
    public function __construct(private readonly GetUserUseCase $useCase) {}

    public function __invoke(int $user): UserResponse
    {
        return new UserResponse(resource: $this->useCase->execute(id: $user));
    }
}
