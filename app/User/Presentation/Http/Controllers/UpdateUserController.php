<?php

declare(strict_types=1);

namespace App\User\Presentation\Http\Controllers;

use App\User\Application\UseCases\UpdateUserUseCase;
use App\User\Presentation\Http\Requests\UpdateUserRequest;
use App\User\Presentation\Http\Responses\UserResponse;

final class UpdateUserController
{
    public function __construct(private readonly UpdateUserUseCase $useCase) {}

    public function __invoke(UpdateUserRequest $request, int $user): UserResponse
    {
        $attributes = $request->validated(key: 'data.attributes');

        return new UserResponse(resource: $this->useCase->execute(
            id: $user,
            name: $attributes['name'] ?? null,
            email: $attributes['email'] ?? null,
        ));
    }
}
