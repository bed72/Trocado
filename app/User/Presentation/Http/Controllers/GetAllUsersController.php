<?php

declare(strict_types=1);

namespace App\User\Presentation\Http\Controllers;

use App\User\Application\UseCases\GetAllUsersUseCase;
use App\User\Presentation\Http\Responses\UserResponse;
use Illuminate\Http\Resources\JsonApi\AnonymousResourceCollection;

final class GetAllUsersController
{
    public function __construct(private readonly GetAllUsersUseCase $useCase) {}

    public function __invoke(): AnonymousResourceCollection
    {
        return UserResponse::collection(resource: $this->useCase->execute());
    }
}
