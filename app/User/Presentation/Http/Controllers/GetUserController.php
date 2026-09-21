<?php

declare(strict_types=1);

namespace App\User\Presentation\Http\Controllers;

use App\User\Application\UseCases\GetUserUseCase;
use App\User\Presentation\Http\Responses\UserResponse;

final class GetUserController
{
    public function __construct(private readonly GetUserUseCase $useCase) {}

    public function __invoke(int $user): UserResponse
    {
        return new UserResponse(resource: $this->useCase->execute(id: $user));
    }
}
