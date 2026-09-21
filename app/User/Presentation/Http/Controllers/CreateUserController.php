<?php

declare(strict_types=1);

namespace App\User\Presentation\Http\Controllers;

use App\User\Application\UseCases\CreateUserUseCase;
use App\User\Presentation\Http\Requests\CreateUserRequest;
use App\User\Presentation\Http\Responses\UserResponse;
use Illuminate\Http\JsonResponse;
use Symfony\Component\HttpFoundation\Response;

final class CreateUserController
{
    public function __construct(private readonly CreateUserUseCase $useCase) {}

    public function __invoke(CreateUserRequest $request): JsonResponse
    {
        $attributes = $request->validated(key: 'data.attributes');
        $user = $this->useCase->execute(
            name: $attributes['name'],
            email: $attributes['email'],
        );

        return (new UserResponse(resource: $user))->response()
            ->setStatusCode(code: Response::HTTP_CREATED)
            ->header(key: 'Location', values: route(name: 'users.get', parameters: ['user' => $user->id]));
    }
}
