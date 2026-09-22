<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Controllers;

use App\Identity\Application\UseCases\SignUpUseCase;
use App\Identity\Presentation\Http\Requests\SignUpRequest;
use App\Identity\Presentation\Http\Responses\SignUpResponse;
use Illuminate\Http\JsonResponse;
use Symfony\Component\HttpFoundation\Response;

final class SignUpController
{
    public function __construct(private readonly SignUpUseCase $useCase) {}

    public function __invoke(SignUpRequest $request): JsonResponse
    {
        $attributes = $request->validated(key: 'data.attributes');
        $userId = $this->useCase->execute(
            name: $attributes['name'],
            email: $attributes['email'],
            password: $attributes['password'],
        );

        return (new SignUpResponse(resource: $userId))->response()
            ->setStatusCode(code: Response::HTTP_CREATED)
            ->header(key: 'Location', values: route(name: 'users.get', parameters: ['user' => $userId]));
    }
}
