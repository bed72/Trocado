<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Controllers;

use App\Identity\Application\UseCases\UpdateUserUseCase;
use App\Identity\Presentation\Http\Requests\UpdateUserRequest;
use App\Identity\Presentation\Http\Responses\UserResponse;

final class UpdateUserController
{
    public function __construct(private readonly UpdateUserUseCase $useCase) {}

    public function __invoke(UpdateUserRequest $request, int $id): UserResponse
    {
        $attributes = $request->validated(key: 'data.attributes');

        return new UserResponse(resource: $this->useCase->execute(
            id: $id,
            name: $attributes['name'] ?? null,
            email: $attributes['email'] ?? null,
        ));
    }
}
