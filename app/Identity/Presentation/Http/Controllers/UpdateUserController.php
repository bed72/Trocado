<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Controllers;

use App\Identity\Application\Data\Input\UpdateInput;
use App\Identity\Application\UseCases\UpdateUserUseCase;
use App\Identity\Presentation\Http\Requests\UpdateUserRequest;
use App\Identity\Presentation\Http\Responses\UserResponse;

use function array_key_exists;

final class UpdateUserController
{
    public function __construct(private readonly UpdateUserUseCase $useCase) {}

    public function __invoke(UpdateUserRequest $request, string $id): UserResponse
    {
        $attributes = $request->validated(key: 'data.attributes');

        return new UserResponse(resource: $this->useCase->execute(
            id: $id,
            input: new UpdateInput(
                name: $attributes['name'] ?? null,
                avatar: $attributes['avatar'] ?? null,
                hasAvatar: array_key_exists('avatar', $attributes),
            ),
        ));
    }
}
