<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Controllers;

use App\Identity\Application\UseCases\GetAllUsersUseCase;
use App\Identity\Presentation\Http\Responses\UserResponse;
use Illuminate\Http\Resources\JsonApi\AnonymousResourceCollection;

final class GetAllUsersController
{
    public function __construct(private readonly GetAllUsersUseCase $useCase) {}

    public function __invoke(): AnonymousResourceCollection
    {
        return UserResponse::collection(resource: $this->useCase->execute());
    }
}
